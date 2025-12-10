import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'local_storage_service.dart';

class MiqaatService {
  static final MiqaatService _instance = MiqaatService._internal();
  factory MiqaatService() => _instance;
  MiqaatService._internal();

  final LocalStorageService _localStorage = LocalStorageService();

  Future<Map<String, dynamic>?> createMiqaat({
    required String miqaatName,
    required String jamaat,
    required String jamiyat,
    required DateTime fromDate,
    required DateTime tillDate,
    required int volunteerLimit,
    String? aboutMiqaat,
  }) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createMiqaat}');
      
      final requestBody = {
        'miqaatName': miqaatName,
        'jamaat': jamaat,
        'jamiyat': jamiyat,
        'fromDate': fromDate.toIso8601String(),
        'tillDate': tillDate.toIso8601String(),
        'volunteerLimit': volunteerLimit,
        'aboutMiqaat': aboutMiqaat,
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
      } else if (response.statusCode == 403) {
        throw Exception('Only Captains can create miqaats');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        String errorMessage = 'Failed to create miqaat. Please try again.';
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

