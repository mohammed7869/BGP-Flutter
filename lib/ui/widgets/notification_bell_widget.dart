import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/notification_api_service.dart';
import '../../core/services/signalr_service.dart';
import '../screens/common/notifications_screen.dart';

/// Bell icon widget with animated unread count badge.
/// Add this to your app bar for notification access.
///
/// Usage:
/// ```dart
/// AppBar(
///   actions: [
///     const NotificationBellWidget(),
///   ],
/// )
/// ```
class NotificationBellWidget extends StatefulWidget {
  const NotificationBellWidget({super.key});

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget>
    with SingleTickerProviderStateMixin {
  final NotificationApiService _apiService = NotificationApiService();
  final SignalRService _signalR = SignalRService();

  int _unreadCount = 0;
  StreamSubscription? _notificationSub;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Setup bounce animation for bell icon when new notification arrives
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Fetch initial unread count
    _fetchUnreadCount();

    // Listen for new notifications to update badge
    _notificationSub = _signalR.onNotificationReceived.listen((_) {
      _onNewNotification();
    });
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final count = await _apiService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (_) {}
  }

  void _onNewNotification() {
    if (mounted) {
      setState(() => _unreadCount++);
      // Trigger bounce animation
      _bounceController.forward().then((_) => _bounceController.reverse());
    }
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined, size: 28),
            if (_unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        tooltip: 'Notifications',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          );
          // Refresh count when returning from notifications screen
          _fetchUnreadCount();
        },
      ),
    );
  }
}
