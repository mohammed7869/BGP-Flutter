import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/qardan_hasana_model.dart';
import 'local_storage_service.dart';

class QardanHasanaService {
  static final QardanHasanaService _instance = QardanHasanaService._internal();
  factory QardanHasanaService() => _instance;
  QardanHasanaService._internal();

  final LocalStorageService _localStorage = LocalStorageService();

  // Base endpoint
  static const String _baseEndpoint = '/api/1/qardan-hasana';

  /// Submit a new Qardan Hasana application
  Future<QardanHasanaApplication> createApplication({
    required String applicantName,
    required String applicantOccupation,
    required String applicantMobile,
    String? reason,
    required double amountRequested,
    required bool termsAccepted,
    required int guarantorMemberId,
  }) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url = Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint');

      final requestBody = {
        'applicantName': applicantName,
        'applicantOccupation': applicantOccupation,
        'applicantMobile': applicantMobile,
        'reason': reason,
        'amountRequested': amountRequested,
        'termsAccepted': termsAccepted,
        'guarantorMemberId': guarantorMemberId,
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
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return QardanHasanaApplication.fromJson(jsonResponse);
      } else {
        _handleErrorResponse(response, 'Failed to submit application');
        throw Exception('Failed to submit application');
      }
    } catch (e) {
      _handleConnectionError(e);
      rethrow;
    }
  }

  /// Get current user's applications
  Future<List<QardanHasanaListItem>> getMyApplications() async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url =
          Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/my-applications');

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
        if (jsonResponse is List) {
          return jsonResponse
              .map((item) =>
                  QardanHasanaListItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Invalid response format');
      } else {
        _handleErrorResponse(response, 'Failed to fetch applications');
        throw Exception('Failed to fetch applications');
      }
    } catch (e) {
      _handleConnectionError(e);
      rethrow;
    }
  }

  /// Get all applications (role-based: captain sees jamaat, admin sees all)
  Future<List<QardanHasanaListItem>> getAllApplications() async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url = Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint');

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
        if (jsonResponse is List) {
          return jsonResponse
              .map((item) =>
                  QardanHasanaListItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Invalid response format');
      } else {
        _handleErrorResponse(response, 'Failed to fetch applications');
        throw Exception('Failed to fetch applications');
      }
    } catch (e) {
      _handleConnectionError(e);
      rethrow;
    }
  }

  /// Check if the current user can apply for Qardan Hasana
  Future<bool> canApply() async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url =
          Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/can-apply');

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
        return jsonResponse['canApply'] == true;
      }
      return true; // Default to allowing if check fails
    } catch (e) {
      return true; // Default to allowing if check fails
    }
  }

  /// Get application by ID
  Future<QardanHasanaApplication> getApplicationById(int id) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url = Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/$id');

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
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return QardanHasanaApplication.fromJson(jsonResponse);
      } else {
        _handleErrorResponse(response, 'Failed to fetch application');
        throw Exception('Failed to fetch application');
      }
    } catch (e) {
      _handleConnectionError(e);
      rethrow;
    }
  }

  /// Get members from same jamaat for guarantor dropdown
  Future<List<JamaatMember>> getMembersByJamaat() async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url =
          Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/members-by-jamaat');

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
        if (jsonResponse is List) {
          return jsonResponse
              .map((item) =>
                  JamaatMember.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Invalid response format');
      } else {
        _handleErrorResponse(response, 'Failed to fetch members');
        throw Exception('Failed to fetch members');
      }
    } catch (e) {
      _handleConnectionError(e);
      rethrow;
    }
  }

  /// Get captain of current user's jamaat
  Future<JamaatMember?> getMyCaptain() async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url =
          Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/my-captain');

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
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return JamaatMember.fromJson(jsonResponse);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        _handleErrorResponse(response, 'Failed to fetch captain');
        throw Exception('Failed to fetch captain');
      }
    } catch (e) {
      _handleConnectionError(e);
      rethrow;
    }
  }

  /// Captain approves the application
  Future<void> captainApprove(int applicationId) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url =
          Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/$applicationId/captain-approve');

      final response = await http
          .put(
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
        return;
      } else {
        _handleErrorResponse(response, 'Failed to approve application');
        throw Exception('Failed to approve application');
      }
    } catch (e) {
      _handleConnectionError(e);
      rethrow;
    }
  }

  /// Download PDF of the application form
  Future<List<int>> downloadPdf(int id) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('User not authenticated');

      final url = Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/$id/pdf');

      final response = await http
          .get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        _handleErrorResponse(response, 'Failed to download PDF');
        throw Exception('Failed to download PDF');
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
