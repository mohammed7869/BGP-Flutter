import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_constants.dart';
import '../models/notification_model.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

/// SignalR connection manager for real-time notification delivery.
///
/// Connects to the .NET SignalR hub at /hubs/notification with Bearer token auth.
/// Auto-reconnects on disconnect with exponential backoff.
/// Routes received notifications to LocalNotificationService for display.
class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  final LocalNotificationService _localNotifications =
      LocalNotificationService();

  HubConnection? _hubConnection;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  Timer? _reconnectTimer;

  /// Stream controller for broadcasting received notifications to UI listeners.
  final StreamController<NotificationModel> _notificationController =
      StreamController<NotificationModel>.broadcast();

  /// Stream of incoming notifications for UI components to listen to.
  Stream<NotificationModel> get onNotificationReceived =>
      _notificationController.stream;

  /// Stream controller for unread count changes.
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  /// Stream of unread count updates.
  Stream<int> get onUnreadCountChanged => _unreadCountController.stream;

  /// Whether the SignalR connection is currently active.
  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  /// Connect to the SignalR notification hub.
  /// Call this after user login.
  Future<void> connect() async {
    if (_isConnecting || isConnected) return;
    _isConnecting = true;
    _shouldReconnect = true;

    try {
      final token = await _localStorage.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('SignalR: No auth token available, skipping connection');
        _isConnecting = false;
        return;
      }

      final hubUrl = ApiConstants.notificationHubUrl;
      debugPrint('SignalR: Connecting to $hubUrl');

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
              skipNegotiation: true,
              transport: HttpTransportType.WebSockets,
            ),
          )
          .withAutomaticReconnect(
            retryDelays: [2000, 5000, 10000, 30000],
          )
          .build();

      // Register event handlers
      _hubConnection!.onclose(({error}) {
        debugPrint('SignalR: Connection closed. Error: $error');
        _onDisconnected();
      });

      _hubConnection!.onreconnecting(({error}) {
        debugPrint('SignalR: Reconnecting... Error: $error');
      });

      _hubConnection!.onreconnected(({connectionId}) {
        debugPrint('SignalR: Reconnected with ID: $connectionId');
        _reconnectAttempts = 0;
      });

      // Listen for notifications from the server
      _hubConnection!.on('ReceiveNotification', _handleNotification);

      // Start the connection
      await _hubConnection!.start();
      _reconnectAttempts = 0;
      debugPrint('SignalR: Connected successfully');
    } catch (e) {
      debugPrint('SignalR: Connection failed: $e');
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  /// Handle incoming notification from SignalR hub.
  Future<void> _handleNotification(List<Object?>? arguments) async {
    try {
      if (arguments == null || arguments.isEmpty) return;

      final data = arguments[0];
      if (data is! Map) {
        debugPrint('SignalR: Received non-map data: ${data.runtimeType}');
        return;
      }

      final json = Map<String, dynamic>.from(data);
      final notification = NotificationModel.fromJson(json);

      debugPrint(
          'SignalR: Received notification: ${notification.title} (${notification.type})');

      // 1. Broadcast to UI listeners (for in-app display)
      _notificationController.add(notification);

      // 2. Show system notification (lock screen + notification tray)
      _showSystemNotification(notification);

      // 3. Broadcast unread count change
      _unreadCountController.add(-1); // -1 signals "increment"
    } catch (e, stackTrace) {
      debugPrint('SignalR: Error handling notification: $e');
      debugPrint('SignalR: Stack trace: $stackTrace');
    }
  }

  /// Show system notification with proper error handling.
  Future<void> _showSystemNotification(NotificationModel notification) async {
    try {
      await _localNotifications.showNotification(notification);
      debugPrint('SignalR: System notification shown successfully');
    } catch (e) {
      debugPrint('SignalR: FAILED to show system notification: $e');
    }
  }

  /// Handle disconnection — schedule reconnect if needed.
  void _onDisconnected() {
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// Schedule a reconnection attempt with exponential backoff.
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint(
          'SignalR: Max reconnect attempts reached ($_maxReconnectAttempts)');
      return;
    }

    _reconnectTimer?.cancel();

    // Exponential backoff: 2s, 4s, 8s, 16s, 30s max
    final delay = Duration(
      seconds: (2 * (1 << _reconnectAttempts)).clamp(2, 30),
    );

    debugPrint(
        'SignalR: Scheduling reconnect attempt ${_reconnectAttempts + 1} in ${delay.inSeconds}s');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });
  }

  /// Mark a notification as read via SignalR (faster than REST).
  Future<void> markAsRead(int notificationId) async {
    if (!isConnected) return;

    try {
      await _hubConnection!.invoke('MarkAsRead', args: [notificationId]);
    } catch (e) {
      debugPrint('SignalR: Error marking notification as read: $e');
    }
  }

  /// Disconnect from the SignalR hub.
  /// Call this on user logout.
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
        debugPrint('SignalR: Disconnected');
      } catch (e) {
        debugPrint('SignalR: Error disconnecting: $e');
      }
    }
  }

  /// Dispose resources.
  void dispose() {
    disconnect();
    _notificationController.close();
    _unreadCountController.close();
  }
}
