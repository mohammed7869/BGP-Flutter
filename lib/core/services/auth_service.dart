import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/auth_models.dart';
import 'local_storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalStorageService _localStorage = LocalStorageService();

  /// Login using ITS ID from users table
  Future<UserAuthResponse?> login(String itsNumber, String password) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}');
      final request = LoginRequest(itsNumber: itsNumber, password: password);

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = UserAuthResponse.fromJson(jsonResponse);

        // Store user data and token in local storage
        await _localStorage.saveUserData(authResponse.toUserData());
        await _localStorage.saveToken(authResponse.token);

        return authResponse;
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        // Try to parse as JSON, if it fails, use the raw response body
        String errorMessage = 'Invalid ITS Number or password.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'] as String? ?? errorMessage;
          } else if (errorBody is String) {
            errorMessage = errorBody;
          }
        } catch (e) {
          // If JSON parsing fails, use the raw response body
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }
        throw Exception(errorMessage);
      } else {
        throw Exception('Login failed. Please try again.');
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('FormatException') ||
          errorMsg.contains('Unexpected character')) {
        // Handle JSON parsing errors
        throw Exception('Invalid response from server. Please try again.');
      } else if (errorMsg.contains('Connection') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('Failed host lookup') ||
          errorMsg.contains('SocketException')) {
        // Show detailed error in debug mode, simple error in release mode
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

  /// Change password for users
  Future<bool> changePassword(
      String itsNumber, String newPassword, String confirmPassword) async {
    try {
      final url =
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.changePassword}');
      final request = ChangePasswordRequest(
        itsNumber: itsNumber,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // Try to parse as JSON, if it fails, use the raw response body
        String errorMessage = 'Failed to change password. Please try again.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'] as String? ?? errorMessage;
          } else if (errorBody is String) {
            errorMessage = errorBody;
          }
        } catch (e) {
          // If JSON parsing fails, use the raw response body
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('FormatException') ||
          errorMsg.contains('Unexpected character')) {
        // Handle JSON parsing errors
        throw Exception('Invalid response from server. Please try again.');
      } else if (errorMsg.contains('Connection') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('Failed host lookup') ||
          errorMsg.contains('SocketException')) {
        // Show detailed error in debug mode, simple error in release mode
        if (kDebugMode) {
          throw Exception(
              'Unable to connect to server. Please check your connection.');
        } else {
          throw Exception('Unable to Connect To Server');
        }
      }
      rethrow;
    }
  }

  /// Get stored user data
  Future<UserData?> getStoredUser() async {
    return await _localStorage.getUserData();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _localStorage.isLoggedIn();
  }

  /// Logout - clear all stored data
  Future<void> logout() async {
    await _localStorage.clearAll();
  }
}
