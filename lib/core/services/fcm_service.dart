import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/notification_model.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';
import 'notification_navigator.dart';

/// Top-level handler for background FCM messages.
/// Must be a top-level function (not inside a class).
/// This runs even when the app is completely killed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized in the background isolate
  await Firebase.initializeApp();
  debugPrint('FCM Background: ${message.notification?.title}');
  // The system automatically displays the notification on the lock screen
  // for "notification" type messages. No manual display needed here.
}

/// Service for Firebase Cloud Messaging integration.
/// Handles FCM token management, foreground/background message routing,
/// and sending the device token to the API server.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final LocalStorageService _localStorage = LocalStorageService();
  final LocalNotificationService _localNotifications =
      LocalNotificationService();

  bool _isInitialized = false;
  String? _currentToken;

  /// Initialize Firebase Messaging.
  /// Call this after Firebase.initializeApp() and after user login.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Request notification permission (Android 13+ / iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: User denied notification permission');
        return;
      }

      debugPrint(
          'FCM: Permission status: ${settings.authorizationStatus}');

      // 2. Get the FCM device token
      _currentToken = await _messaging.getToken();
      debugPrint('FCM: Device token: $_currentToken');

      if (_currentToken != null) {
        await _sendTokenToServer(_currentToken!);
      }

      // 3. Listen for token refresh (Google can rotate tokens)
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM: Token refreshed: $newToken');
        _currentToken = newToken;
        await _sendTokenToServer(newToken);
      });

      // 4. Handle foreground messages (app is open and visible)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Handle notification tap when app was in background (not killed)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 6. Check if app was launched from a terminated state by tapping a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _isInitialized = true;
      debugPrint('FCM: Initialized successfully');
    } catch (e) {
      debugPrint('FCM: Initialization error: $e');
    }
  }

  /// Handle messages received while app is in the foreground.
  /// FCM does NOT automatically display a notification for foreground messages,
  /// so we use flutter_local_notifications to show it manually.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
        'FCM Foreground: ${message.notification?.title} - ${message.notification?.body}');

    final notification = message.notification;
    if (notification == null) return;

    // Convert FCM message to our NotificationModel and show via local notifications
    final type = message.data['type'] ?? 'general';
    final referenceId = message.data['referenceId'];

    final model = NotificationModel(
      id: message.hashCode,
      title: notification.title ?? '',
      body: notification.body ?? '',
      type: type,
      referenceId: referenceId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    _localNotifications.showNotification(model);
  }

  /// Handle when user taps a notification (app was in background or terminated).
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM: Notification tapped, data: ${message.data}');

    final type = message.data['type'] ?? 'general';
    final referenceId = message.data['referenceId'];

    if (type.isNotEmpty) {
      final payload = referenceId != null ? '$type:$referenceId' : type;
      // Use the existing NotificationNavigator for deep-linking
      NotificationNavigator.handleNotificationTap(payload);
    }
  }

  /// Send the FCM token to the API server so it can push notifications to this device.
  Future<void> _sendTokenToServer(String token) async {
    try {
      final authToken = await _localStorage.getToken();
      if (authToken == null || authToken.isEmpty) {
        debugPrint('FCM: No auth token, skipping server registration');
        return;
      }

      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.registerFcmToken}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('FCM: Token registered with server successfully');
      } else {
        debugPrint(
            'FCM: Failed to register token: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('FCM: Error sending token to server: $e');
    }
  }

  /// Get the current FCM token (useful for debugging).
  String? get currentToken => _currentToken;
}
