import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'local_storage_service.dart';

class SurveyService {
  static final SurveyService _instance = SurveyService._internal();
  factory SurveyService() => _instance;
  SurveyService._internal();

  final LocalStorageService _localStorage = LocalStorageService();

  // Base endpoint
  static const String _baseEndpoint = '/api/1/survey';

  /// Submit survey form
  Future<Map<String, dynamic>> submitSurvey({
    required int department,
    required int zone,
  }) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url = Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint');

      final requestBody = {
        'department': department,
        'zone': zone,
      };

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        _handleErrorResponse(response, 'Failed to submit survey');
        throw Exception('Failed to submit survey');
      }
    } catch (e) {
      _handleConnectionError(e);
      rethrow;
    }
  }

  /// Check if current user has submitted survey
  Future<bool> hasSubmitted() async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url =
          Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/has-submitted');

      final response = await http
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['hasSubmitted'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get current user's survey response (for preview)
  Future<Map<String, dynamic>?> getMySurvey() async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url =
          Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/my-survey');

      final response = await http
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        _handleErrorResponse(response, 'Failed to fetch survey');
        throw Exception('Failed to fetch survey');
      }
    } catch (e) {
      _handleConnectionError(e);
      rethrow;
    }
  }

  // ─── Error Handling ──────────────────────────

  void _handleErrorResponse(http.Response response, String defaultMessage) {
    if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    } else if (response.statusCode == 403) {
      throw Exception('You do not have permission for this action.');
    }

    String errorMessage = defaultMessage;
    try {
      final errorBody = jsonDecode(response.body);
      if (errorBody is Map && errorBody.containsKey('message')) {
        errorMessage = errorBody['message'] as String? ?? defaultMessage;
      }
    } catch (_) {
      if (response.body.isNotEmpty) errorMessage = response.body;
    }
    throw Exception(errorMessage);
  }

  void _handleConnectionError(dynamic e) {
    final errorMsg = e.toString();
    if (errorMsg.contains('FormatException') ||
        errorMsg.contains('Unexpected character')) {
      throw Exception('Invalid response from server. Please try again.');
    } else if (errorMsg.contains('Connection') ||
        errorMsg.contains('timeout') ||
        errorMsg.contains('Failed host lookup') ||
        errorMsg.contains('SocketException')) {
      if (kDebugMode) {
        throw Exception(
            'Unable to connect to server. Please check:\n1. API is running\n2. Correct IP address\n3. Same Wi-Fi network');
      } else {
        throw Exception('Unable to Connect To Server');
      }
    }
  }
}
