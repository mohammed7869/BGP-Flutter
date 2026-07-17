/// Model class for notifications received from the API.
/// Matches the NotificationDto from the .NET backend.
class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      referenceId: json['referenceId']?.toString(),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? _parseUtcDate(json['createdAt'].toString())
          : DateTime.now(),
      readAt: json['readAt'] != null
          ? _parseUtcDate(json['readAt'].toString())
          : null,
    );
  }

  /// Parse date string from server as UTC and convert to local time.
  /// Server stores dates in UTC (via UTC_TIMESTAMP / GETUTCDATE).
  static DateTime _parseUtcDate(String dateStr) {
    // If the string doesn't end with Z or have timezone info, treat as UTC
    if (!dateStr.endsWith('Z') && !dateStr.contains('+') && !dateStr.contains('-', 10)) {
      dateStr = '${dateStr}Z';
    }
    return DateTime.parse(dateStr).toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'referenceId': referenceId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  /// Returns a user-friendly label for the notification type.
  String get typeLabel {
    switch (type) {
      case 'miqaat':
        return 'Miqaat';
      case 'qardan':
        return 'Qardan Hasana';
      case 'admin':
        return 'Admin';
      case 'survey':
        return 'Survey';
      case 'member':
        return 'Member';
      case 'general':
      default:
        return 'General';
    }
  }

  /// Returns a copy with isRead set to true.
  NotificationModel markAsRead() {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
      isRead: true,
      createdAt: createdAt,
      readAt: DateTime.now(),
    );
  }
}

/// Response model for paginated notification list.
class NotificationListResponse {
  final List<NotificationModel> notifications;
  final int totalCount;
  final int unreadCount;
  final int page;
  final int pageSize;

  NotificationListResponse({
    required this.notifications,
    required this.totalCount,
    required this.unreadCount,
    required this.page,
    required this.pageSize,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final notifList = (json['notifications'] as List<dynamic>?)
            ?.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return NotificationListResponse(
      notifications: notifList,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );
  }
}
