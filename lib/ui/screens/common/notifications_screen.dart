import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_api_service.dart';
import '../../../core/services/notification_navigator.dart';
import '../../../core/services/signalr_service.dart';

/// Full-screen notification center showing all notifications grouped by date.
/// Supports pull-to-refresh, swipe-to-dismiss, mark as read, and deep linking.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationApiService _apiService = NotificationApiService();
  final SignalRService _signalR = SignalRService();
  final ScrollController _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  int _totalCount = 0;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  StreamSubscription? _notificationSub;

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    // Listen for new real-time notifications
    _notificationSub = _signalR.onNotificationReceived.listen((notification) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, notification);
          _unreadCount++;
          _totalCount++;
        });
      }
    });

    // Pagination: load more when scrolled to bottom
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  Future<void> _loadNotifications() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getNotifications(page: 1, pageSize: 20);
      if (mounted) {
        setState(() {
          _notifications = response.notifications;
          _unreadCount = response.unreadCount;
          _totalCount = response.totalCount;
          _currentPage = 1;
          _hasMore = response.notifications.length < response.totalCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notifications';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final nextPage = _currentPage + 1;
      final response =
          await _apiService.getNotifications(page: nextPage, pageSize: 20);
      if (mounted) {
        setState(() {
          _notifications.addAll(response.notifications);
          _currentPage = nextPage;
          _hasMore = _notifications.length < response.totalCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification, int index) async {
    if (notification.isRead) return;

    setState(() {
      _notifications[index] = notification.markAsRead();
      _unreadCount = (_unreadCount - 1).clamp(0, _totalCount);
    });

    await _apiService.markAsRead(notification.id);
  }

  /// Mark as read and navigate to the relevant screen or show details.
  void _onNotificationTap(NotificationModel notification, int index) {
    _markAsRead(notification, index);

    // If there's an external link, handle it
    if (notification.linkUrl != null && notification.linkUrl!.isNotEmpty) {
      String payload = '${notification.type}:${notification.referenceId ?? notification.id}|linkUrl:${notification.linkUrl}';
      NotificationNavigator.handleNotificationTap(payload);
      return;
    }

    // For these types, show a dialog with image and details directly instead of navigating
    if (['admin', 'general', 'survey', 'member'].contains(notification.type)) {
      _showNotificationDetailsDialog(notification);
      return;
    }

    String payload = '${notification.type}:${notification.referenceId ?? notification.id}';
    NotificationNavigator.handleNotificationTap(payload);
  }

  void _showNotificationDetailsDialog(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              // Image (if available)
              if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty)
                Image.network(
                  notification.imageUrl!,
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
              // Body
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  notification.body,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications
          .map((n) => n.isRead ? n : n.markAsRead())
          .toList();
      _unreadCount = 0;
    });

    await _apiService.markAllAsRead();
  }

  Future<void> _deleteNotification(int index) async {
    final notification = _notifications[index];
    setState(() {
      _notifications.removeAt(index);
      _totalCount--;
      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _totalCount);
      }
    });

    await _apiService.deleteNotification(notification.id);
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount unread',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Read All'),
            ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_error != null && _notifications.isEmpty) {
      return _buildErrorView(theme);
    }

    if (!_isLoading && _notifications.isEmpty) {
      return _buildEmptyView(theme);
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final notification = _notifications[index];
          final showDateHeader = index == 0 ||
              !_isSameDay(
                _notifications[index - 1].createdAt,
                notification.createdAt,
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateHeader) _buildDateHeader(notification.createdAt, theme),
              _buildNotificationTile(notification, index, theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, ThemeData theme) {
    final now = DateTime.now();
    String label;

    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat('EEEE, MMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
      NotificationModel notification, int index, ThemeData theme) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteNotification(index),
      child: InkWell(
        onTap: () => _onNotificationTap(notification, index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? null
                : theme.colorScheme.primary.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            notification.imageUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    if (notification.linkUrl != null && notification.linkUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Row(
                          children: [
                            Icon(Icons.link, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to open link',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor(notification.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        notification.typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getTypeColor(notification.type),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 72,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Get icon for notification type.
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'miqaat':
        return Icons.event;
      case 'qardan':
        return Icons.account_balance_wallet;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'survey':
        return Icons.poll;
      case 'member':
        return Icons.person;
      case 'general':
      default:
        return Icons.notifications;
    }
  }

  /// Get color for notification type.
  Color _getTypeColor(String type) {
    switch (type) {
      case 'miqaat':
        return const Color(0xFF0D7377);
      case 'qardan':
        return const Color(0xFF6C63FF);
      case 'admin':
        return const Color(0xFFE53935);
      case 'survey':
        return const Color(0xFFFFA726);
      case 'member':
        return const Color(0xFF43A047);
      case 'general':
      default:
        return const Color(0xFF546E7A);
    }
  }

  /// Format time for display.
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(dateTime);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
