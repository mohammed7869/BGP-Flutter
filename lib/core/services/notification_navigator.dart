import 'package:flutter/material.dart';
import '../../ui/screens/admin/adminDashboard.dart';
import '../../ui/screens/common/notifications_screen.dart';
import '../../ui/screens/qardan_hasana/qardan_detail_screen.dart';

/// Handles notification tap deep-linking — routes to the correct screen
/// based on the notification payload format: "type:referenceId"
class NotificationNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Parse payload and navigate to the appropriate screen.
  /// Payload format: "type:referenceId"
  static void handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;

    debugPrint('NotificationNavigator: Handling tap with payload: $payload');

    final parts = payload.split(':');
    final type = parts[0];
    final referenceId = parts.length > 1 ? parts[1] : null;

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('NotificationNavigator: Navigator not ready');
      return;
    }

    switch (type) {
      case 'miqaat':
        // Navigate to Dashboard which shows miqaat listing
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AdminDashboardScreen(),
          ),
          (route) => false, // Remove all previous routes
        );
        break;

      case 'qardan':
        final appId = int.tryParse(referenceId ?? '');
        if (appId != null) {
          navigator.push(
            MaterialPageRoute(
              builder: (context) => QardanDetailScreen(applicationId: appId),
            ),
          );
        } else {
          navigator.push(
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          );
        }
        break;

      case 'admin':
      case 'survey':
      case 'member':
      case 'general':
      default:
        navigator.push(
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
        break;
    }
  }
}
