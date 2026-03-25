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

  /// Validates the stored session with the API.
  ///
  /// If the server explicitly says the token is invalid, local session data is
  /// cleared so the user is taken back to login. Network/server issues keep the
  /// current local session so users are not logged out unnecessarily.
  Future<bool> validateStoredSession() async {
    final isLoggedIn = await _localStorage.isLoggedIn();
    final token = await _localStorage.getToken();
    final userData = await _localStorage.getUserData();

    if (!isLoggedIn || token == null || token.isEmpty || userData == null) {
      await _localStorage.clearAll();
      return false;
    }

    try {
      final url =
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getUserProfile}');
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
        final refreshedUser = UserData(
          id: (jsonResponse['id'] as num?)?.toInt() ?? userData.id,
          profile: jsonResponse['profile']?.toString() ?? userData.profile,
          itsId: jsonResponse['itsId']?.toString() ?? userData.itsId,
          fullName: jsonResponse['fullName']?.toString() ?? userData.fullName,
          email: jsonResponse['email']?.toString() ?? userData.email,
          rank: jsonResponse['rank']?.toString() ?? userData.rank,
          roles: (jsonResponse['roles'] as num?)?.toInt() ?? userData.roles,
          jamiyat: jsonResponse['jamiyat']?.toString() ?? userData.jamiyat,
          jamaat: jsonResponse['jamaat']?.toString() ?? userData.jamaat,
          gender: jsonResponse['gender']?.toString() ?? userData.gender,
          age: (jsonResponse['age'] as num?)?.toInt() ?? userData.age,
          contact: jsonResponse['contact']?.toString() ?? userData.contact,
          dateOfBirth:
              jsonResponse['dateOfBirth']?.toString() ?? userData.dateOfBirth,
          role: userData.role,
        );

        await _localStorage.saveUserData(refreshedUser);
        return true;
      }

      if (response.statusCode == 401) {
        await _localStorage.clearAll();
        return false;
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  /// Update user profile (email, contact, dateOfBirth)
  Future<bool> updateProfile({
    String? email,
    String? contact,
    String? dateOfBirth,
  }) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateProfile}');

      final body = <String, dynamic>{};
      if (email != null) body['email'] = email;
      if (contact != null) body['contact'] = contact;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      if (response.statusCode == 200) {
        // Update local storage with new data
        final userData = await _localStorage.getUserData();
        if (userData != null) {
          final updatedUserData = UserData(
            id: userData.id,
            profile: userData.profile,
            itsId: userData.itsId,
            fullName: userData.fullName,
            email: email ?? userData.email,
            rank: userData.rank,
            roles: userData.roles,
            jamiyat: userData.jamiyat,
            jamaat: userData.jamaat,
            gender: userData.gender,
            age: userData.age,
            contact: contact ?? userData.contact,
            dateOfBirth: dateOfBirth ?? userData.dateOfBirth,
            role: userData.role,
          );
          await _localStorage.saveUserData(updatedUserData);
        }
        return true;
      } else {
        String errorMessage = 'Failed to update profile.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'] as String? ?? errorMessage;
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Connection') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('Failed host lookup') ||
          errorMsg.contains('SocketException')) {
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

  /// Logout - clear all stored data
  Future<void> logout() async {
    await _localStorage.clearAll();
  }

  /// Forgot password - request OTP
  Future<ForgotPasswordResponse> forgotPassword(String itsNumber) async {
    try {
      final url =
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.forgotPassword}');
      final request = ForgotPasswordRequest(itsNumber: itsNumber);

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ForgotPasswordResponse.fromJson(jsonResponse);
      } else {
        final message = jsonResponse['message'] as String? ?? 'Request failed';
        throw Exception(message);
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Connection') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('Failed host lookup') ||
          errorMsg.contains('SocketException')) {
        if (kDebugMode) {
          throw Exception('Unable to connect to server. Please check your connection.');
        } else {
          throw Exception('Unable to Connect To Server');
        }
      }
      rethrow;
    }
  }

  /// Verify OTP
  Future<VerifyOtpResponse> verifyOtp(String itsNumber, String otpCode) async {
    try {
      final url =
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyOtp}');
      final request = VerifyOtpRequest(itsNumber: itsNumber, otpCode: otpCode);

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

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return VerifyOtpResponse.fromJson(jsonResponse);
      } else {
        final message = jsonResponse['message'] as String? ?? 'Invalid OTP';
        throw Exception(message);
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Connection') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('Failed host lookup') ||
          errorMsg.contains('SocketException')) {
        if (kDebugMode) {
          throw Exception('Unable to connect to server. Please check your connection.');
        } else {
          throw Exception('Unable to Connect To Server');
        }
      }
      rethrow;
    }
  }

  /// Reset password
  Future<ResetPasswordResponse> resetPassword(
      String itsNumber, String otpCode, String newPassword, String confirmPassword) async {
    try {
      final url =
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resetPassword}');
      final request = ResetPasswordRequest(
        itsNumber: itsNumber,
        otpCode: otpCode,
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

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ResetPasswordResponse.fromJson(jsonResponse);
      } else {
        final message = jsonResponse['message'] as String? ?? 'Password reset failed';
        throw Exception(message);
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Connection') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('Failed host lookup') ||
          errorMsg.contains('SocketException')) {
        if (kDebugMode) {
          throw Exception('Unable to connect to server. Please check your connection.');
        } else {
          throw Exception('Unable to Connect To Server');
        }
      }
      rethrow;
    }
  }
}

