import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'local_storage_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final LocalStorageService _localStorage = LocalStorageService();

  /// Creates a new member. When called by a Captain, is_approved will be set to false.
  Future<Map<String, dynamic>?> createMember({
    required String itsId,
    required String fullName,
    required String email,
    String? contact,
    String? rank,
    String? jamiyat,
    String? jamaat,
    String? gender,
    int? age,
    String? password,
  }) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createUser}');
      
      final requestBody = {
        'itsId': itsId,
        'fullName': fullName,
        'email': email,
        if (contact != null && contact.isNotEmpty) 'contact': contact,
        if (rank != null && rank.isNotEmpty) 'rank': rank,
        if (jamiyat != null && jamiyat.isNotEmpty) 'jamiyat': jamiyat,
        if (jamaat != null && jamaat.isNotEmpty) 'jamaat': jamaat,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
        if (age != null) 'age': age,
        if (password != null && password.isNotEmpty) 'password': password,
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
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return jsonResponse;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        String errorMessage = 'Failed to create member. Please try again.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'] as String? ?? errorMessage;
          } else if (errorBody is String) {
            errorMessage = errorBody;
          }
        } catch (e) {
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
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
              'Unable to connect to server. Please check:\n1. API is running\n2. Correct IP address in api_constants.dart\n3. Phone and laptop on same Wi-Fi');
        } else {
          throw Exception('Unable to Connect To Server');
        }
      }
      rethrow;
    }
  }

  /// Approves a member. Only Admin can approve members.
  Future<void> approveMember(int memberId) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.approveMember}/$memberId/approve');

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
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Only Admin can approve members');
      } else {
        String errorMessage = 'Failed to approve member. Please try again.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'] as String? ?? errorMessage;
          } else if (errorBody is String) {
            errorMessage = errorBody;
          }
        } catch (e) {
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
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
              'Unable to connect to server. Please check:\n1. API is running\n2. Correct IP address in api_constants.dart\n3. Phone and laptop on same Wi-Fi');
        } else {
          throw Exception('Unable to Connect To Server');
        }
      }
      rethrow;
    }
  }

  /// Gets members by jamaat. Returns list of members in the same jamaat.
  Future<List<Map<String, dynamic>>> getMembersByJamaat(String jamaat) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getMembersByJamaat}/$jamaat');

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
          return jsonResponse.cast<Map<String, dynamic>>();
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        String errorMessage = 'Failed to load members. Please try again.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'] as String? ?? errorMessage;
          } else if (errorBody is String) {
            errorMessage = errorBody;
          }
        } catch (e) {
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
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
              'Unable to connect to server. Please check:\n1. API is running\n2. Correct IP address in api_constants.dart\n3. Phone and laptop on same Wi-Fi');
        } else {
          throw Exception('Unable to Connect To Server');
        }
      }
      rethrow;
    }
  }
}

