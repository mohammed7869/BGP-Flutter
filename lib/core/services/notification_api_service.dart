import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/notification_model.dart';
import 'local_storage_service.dart';

/// REST API service for notification endpoints.
/// Handles fetching notifications, marking as read, and getting unread counts.
class NotificationApiService {
  static final NotificationApiService _instance =
      NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  final LocalStorageService _localStorage = LocalStorageService();

  /// Get auth headers with Bearer token.
  Future<Map<String, String>> _getHeaders() async {
    final token = await _localStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch paginated notifications for the current user.
  Future<NotificationListResponse> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.notifications}?page=$page&pageSize=$pageSize');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return NotificationListResponse.fromJson(json);
      } else {
        throw Exception('Failed to fetch notifications');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Get unread notification count.
  Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.unreadCount}');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark a single notification as read.
  Future<bool> markAsRead(int notificationId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.markRead}/$notificationId');

      final response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read.
  Future<bool> markAllAsRead() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.markAllRead}');

      final response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete a notification.
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.notifications}/$notificationId');

      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }
}
