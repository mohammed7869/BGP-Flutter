import 'package:flutter/material.dart';
import '../../ui/screens/admin/adminDashboard.dart';
import '../../ui/screens/common/notifications_screen.dart';
import '../../ui/screens/qardan_hasana/qardan_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'miqaat_service.dart';

/// Handles notification tap deep-linking — routes to the correct screen
/// based on the notification payload format: "type:referenceId"
class NotificationNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Parse payload and navigate to the appropriate screen.
  /// Payload format: "type:referenceId"
  static void handleNotificationTap(String? payload) async {
    if (payload == null || payload.isEmpty) return;

    debugPrint('NotificationNavigator: Handling tap with payload: $payload');

    final parts = payload.split('|');
    final typeAndRef = parts[0].split(':');
    final type = typeAndRef[0];
    final referenceId = typeAndRef.length > 1 ? typeAndRef[1] : null;

    String? linkUrl;
    if (parts.length > 1 && parts[1].startsWith('linkUrl:')) {
      linkUrl = parts[1].substring(8);
    }

    // Launch external link if present
    if (linkUrl != null && linkUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(linkUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return; // Stop here if it's an external link
        }
      } catch (e) {
        debugPrint('Error launching linkUrl: $e');
      }
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('NotificationNavigator: Navigator not ready');
      return;
    }

    switch (type) {
      case 'miqaat':
        final miqaatId = int.tryParse(referenceId ?? '');
        if (miqaatId != null) {
          final miqaatData = await MiqaatService().getMiqaatById(miqaatId);
          if (miqaatData != null && navigatorKey.currentContext != null) {
            await showDialog(
              context: navigatorKey.currentContext!,
              builder: (context) {
                return AlertDialog(
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with close button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Miqaat Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Icon(Icons.close, size: 20),
                            ),
                          ],
                        ),
                      ),
                      // Image (if available)
                      if (miqaatData['notificationImage'] != null && miqaatData['notificationImage'].isNotEmpty)
                        Image.network(
                          miqaatData['notificationImage'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              height: 150,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      // About Miqaat
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          miqaatData['aboutMiqaat'] ?? 'A new Miqaat has been created.',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        }

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
