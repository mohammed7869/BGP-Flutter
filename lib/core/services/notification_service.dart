import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

/// Top-level callback for notification taps when app was terminated.
/// Must be a top-level function (not inside a class).
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // This will be handled when the app launches
  debugPrint('Background notification tapped: ${response.payload}');
}

/// Service for displaying rich Android system notifications.
/// Configures notification channels, styles (BigText, Inbox), and action buttons
/// similar to WhatsApp/Snapchat notifications.
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Callback for when user taps on a notification.
  Function(String? payload)? onNotificationTapped;

  /// Initialize the local notification plugin with Android settings.
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create notification channels for different types
    await _createNotificationChannels();

    _isInitialized = true;
    debugPrint('LocalNotificationService initialized');
  }

  /// Create Android notification channels for different notification types.
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Main notification channel
    const mainChannel = AndroidNotificationChannel(
      'bgp_notifications',
      'Burhani Guards Notifications',
      description: 'Notifications from Burhani Guards Pune',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Miqaat channel
    const miqaatChannel = AndroidNotificationChannel(
      'bgp_miqaat',
      'Miqaat Updates',
      description: 'Miqaat enrollment and schedule notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Qardan Hasana channel
    const qardanChannel = AndroidNotificationChannel(
      'bgp_qardan',
      'Qardan Hasana',
      description: 'Loan and repayment notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Admin channel
    const adminChannel = AndroidNotificationChannel(
      'bgp_admin',
      'Admin Notifications',
      description: 'Administrative announcements and alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(mainChannel);
    await androidPlugin.createNotificationChannel(miqaatChannel);
    await androidPlugin.createNotificationChannel(qardanChannel);
    await androidPlugin.createNotificationChannel(adminChannel);
  }

  /// Handle notification tap response.
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    onNotificationTapped?.call(response.payload);
  }

  /// Check if the app was launched from a notification tap.
  Future<String?> getInitialNotificationPayload() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      return launchDetails.notificationResponse!.payload;
    }
    return null;
  }

  /// Show a rich notification in the Android system tray.
  /// Uses BigTextStyle for expandable text (like WhatsApp notifications).
  Future<void> showNotification(NotificationModel notification) async {
    final channelId = _getChannelId(notification.type);
    final channelName = _getChannelName(notification.type);

    // BigTextStyle — expandable notification like WhatsApp
    final bigTextStyle = BigTextStyleInformation(
      notification.body,
      htmlFormatBigText: false,
      contentTitle: '<b>${notification.title}</b>',
      htmlFormatContentTitle: true,
      summaryText: notification.typeLabel,
      htmlFormatSummaryText: false,
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: bigTextStyle,
      // Group notifications by type (like WhatsApp groups messages)
      groupKey: 'bgp_${notification.type}',
      category: AndroidNotificationCategory.message,
      autoCancel: true,
      showWhen: false,
      // Visibility on lock screen
      visibility: NotificationVisibility.public,
      // Full screen intent for heads-up display
      fullScreenIntent: true,
      // LED and vibration
      enableLights: true,
      color: const Color(0xFF0D7377),
      ledColor: const Color(0xFF0D7377),
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      playSound: true,
      ticker: '${notification.title}: ${notification.body}',
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      notification.id,
      notification.title,
      notification.body,
      details,
      payload: '${notification.type}:${notification.referenceId ?? notification.id}',
    );

    debugPrint('System notification shown: ${notification.title} on channel $channelId');
  }

  /// Get the Android notification channel ID for a notification type.
  String _getChannelId(String type) {
    switch (type) {
      case 'miqaat':
        return 'bgp_miqaat';
      case 'qardan':
        return 'bgp_qardan';
      case 'admin':
        return 'bgp_admin';
      default:
        return 'bgp_notifications';
    }
  }

  /// Get the channel display name for a notification type.
  String _getChannelName(String type) {
    switch (type) {
      case 'miqaat':
        return 'Miqaat Updates';
      case 'qardan':
        return 'Qardan Hasana';
      case 'admin':
        return 'Admin Notifications';
      default:
        return 'Burhani Guards Notifications';
    }
  }

  /// Cancel a specific notification.
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Request notification permission (Android 13+).
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    }
    return true;
  }
}
