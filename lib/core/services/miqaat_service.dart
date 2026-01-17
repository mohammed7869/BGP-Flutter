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

  /// Creates a new miqaat. Only Captains can create miqaats.
  /// 
  /// IMPORTANT: Once a miqaat is created by a Captain, it cannot be edited
  /// or deleted by the Captain. This is by design to maintain data integrity.
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

  Future<JamiyatJamaatResponse?> getJamiyatJamaatWithCounts() async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getJamiyatJamaat}');

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
        return JamiyatJamaatResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        String errorMessage = 'Failed to fetch jamiyat/jamaat data. Please try again.';
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

  Future<List<Miqaat>> getAllMiqaats() async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllMiqaats}');

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
              .map((item) => Miqaat.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Invalid response format from server.');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        String errorMessage = 'Failed to fetch miqaats. Please try again.';
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

  Future<List<Miqaat>> getMemberMiqaats(int memberId) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getMemberMiqaats}/$memberId');

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
              .map((item) => Miqaat.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Invalid response format from server.');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        String errorMessage = 'Failed to fetch member miqaats. Please try again.';
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

  Future<void> updateMemberMiqaatStatus({
    required int memberId,
    required int miqaatId,
    required String status,
  }) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateMemberMiqaatStatus}/$miqaatId/member/$memberId/status');

      final requestBody = {
        'status': status,
      };

      final response = await http
          .patch(
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
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('You can only update your own miqaat status');
      } else {
        String errorMessage = 'Failed to update miqaat status. Please try again.';
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

  Future<List<EnrolledMember>> getEnrolledMembersByMiqaatId(int miqaatId) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getEnrolledMembers}/$miqaatId/enrolled-members');

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
              .map((item) => EnrolledMember.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Invalid response format from server.');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Only Captains can view enrolled members');
      } else {
        String errorMessage = 'Failed to fetch enrolled members. Please try again.';
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

  Future<List<EnrolledMember>> getApprovedMembersForAttendance(int miqaatId,
      {int day = 1}) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.getEnrolledMembers}/$miqaatId/approved-members-for-attendance?day=$day');

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
              .map((item) => EnrolledMember.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Invalid response format from server.');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Only Captains can view approved members for attendance');
      } else {
        String errorMessage = 'Failed to fetch approved members. Please try again.';
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

  Future<void> updateFinalStatus({
    required int miqaatId,
    required int memberId,
    required String finalStatus,
  }) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateMemberMiqaatStatus}/$miqaatId/member/$memberId/final-status');

      final requestBody = {
        'status': finalStatus,
      };

      final response = await http
          .patch(
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
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Only Captains can update final status');
      } else {
        String errorMessage = 'Failed to update final status. Please try again.';
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

  Future<void> markAttendanceBatch({
    required int miqaatId,
    required int day,
    required List<int> memberIds,
  }) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateMemberMiqaatStatus}/$miqaatId/mark-attendance');

      final requestBody = {
        'day': day,
        'memberIds': memberIds,
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
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Only Captains can mark attendance');
      } else {
        String errorMessage = 'Failed to mark attendance. Please try again.';
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

  Future<MemberMiqaatAttendanceHistory> getMemberAttendanceHistory(
      int memberId) async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.getEnrolledMembers}/member/$memberId/attendance-history');

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
        return MemberMiqaatAttendanceHistory.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Only Captains can view member attendance history');
      } else {
        String errorMessage = 'Failed to fetch attendance history.';
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
              'Unable to connect to server. Please check:\n1. API is running\n2. Correct IP address in api_constants.dart\n3. Phone and laptop on same Wi-Fi');
        } else {
          throw Exception('Unable to Connect To Server');
        }
      }
      rethrow;
    }
  }
}

class Miqaat {
  final int id;
  final String miqaatName;
  final String jamaat;
  final String jamiyat;
  final DateTime fromDate;
  final DateTime tillDate;
  final int miqaatDays;
  final int volunteerLimit;
  final String? aboutMiqaat;
  final String adminApproval;
  final String? memberStatus;
  final String? finalStatus;
  final String captainName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Miqaat({
    required this.id,
    required this.miqaatName,
    required this.jamaat,
    required this.jamiyat,
    required this.fromDate,
    required this.tillDate,
    required this.miqaatDays,
    required this.volunteerLimit,
    this.aboutMiqaat,
    required this.adminApproval,
    this.memberStatus,
    this.finalStatus,
    required this.captainName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Miqaat.fromJson(Map<String, dynamic> json) {
    final from = DateTime.parse(json['fromDate'] as String);
    final till = DateTime.parse(json['tillDate'] as String);
    final computedDays = till.difference(from).inDays + 1;

    return Miqaat(
      id: json['id'] as int? ?? 0,
      miqaatName: json['miqaatName'] as String? ?? '',
      jamaat: json['jamaat'] as String? ?? '',
      jamiyat: json['jamiyat'] as String? ?? '',
      fromDate: from,
      tillDate: till,
      miqaatDays: (json['miqaatDays'] as num?)?.toInt() ??
          (json['miqaat_days'] as num?)?.toInt() ??
          (computedDays < 1 ? 1 : computedDays),
      volunteerLimit: json['volunteerLimit'] as int? ?? 0,
      aboutMiqaat: json['aboutMiqaat'] as String?,
      adminApproval: json['adminApproval'] as String? ?? 'Pending',
      memberStatus: json['status'] as String? ??
          json['memberStatus'] as String? ??
          json['member_status'] as String?,
      finalStatus: json['finalStatus'] as String? ??
          json['final_status'] as String?,
      captainName: json['captainName'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  String get durationLabel => '$miqaatDays day${miqaatDays == 1 ? '' : 's'}';

  String get formattedDateRange {
    final from = _formatDate(fromDate);
    final till = _formatDate(tillDate);
    return '$from - $till';
  }

  String _formatDate(DateTime date) {
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }
}

class JamiyatJamaatResponse {
  final List<JamiyatItem> jamiyats;
  final List<JamaatItem> jamaats;

  JamiyatJamaatResponse({
    required this.jamiyats,
    required this.jamaats,
  });

  factory JamiyatJamaatResponse.fromJson(Map<String, dynamic> json) {
    return JamiyatJamaatResponse(
      jamiyats: (json['jamiyats'] as List<dynamic>?)
              ?.map((item) => JamiyatItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      jamaats: (json['jamaats'] as List<dynamic>?)
              ?.map((item) => JamaatItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class JamiyatItem {
  final String name;
  final int count;

  JamiyatItem({
    required this.name,
    required this.count,
  });

  factory JamiyatItem.fromJson(Map<String, dynamic> json) {
    return JamiyatItem(
      name: json['name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  String get displayName => '$name ($count)';
}

class JamaatItem {
  final String name;
  final int count;

  JamaatItem({
    required this.name,
    required this.count,
  });

  factory JamaatItem.fromJson(Map<String, dynamic> json) {
    return JamaatItem(
      name: json['name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  String get displayName => '$name ($count)';
}

class EnrolledMember {
  final int id;
  final String fullName;
  final String? email;
  final String? contact;
  final String? rank;
  final String? jamaat;
  final String? jamiyat;
  final String? finalStatus;
  final String? itsId;
  final bool? isAttended;

  EnrolledMember({
    required this.id,
    required this.fullName,
    this.email,
    this.contact,
    this.rank,
    this.jamaat,
    this.jamiyat,
    this.finalStatus,
    this.itsId,
    this.isAttended,
  });

  factory EnrolledMember.fromJson(Map<String, dynamic> json) {
    // Handle both int and long (which comes as int in JSON)
    final idValue = json['id'];
    final id = idValue is int ? idValue : (idValue as num?)?.toInt() ?? 0;
    
    return EnrolledMember(
      id: id,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      contact: json['contact'] as String?,
      rank: json['rank'] as String?,
      jamaat: json['jamaat'] as String?,
      jamiyat: json['jamiyat'] as String?,
      finalStatus: json['finalStatus'] as String?,
      itsId: json['itsId'] as String?,
      isAttended: json['isAttended'] as bool?,
    );
  }
}

class MemberMiqaatAttendanceHistory {
  final int memberId;
  final String fullName;
  final String? itsId;
  final int totalPoints;
  final List<MemberMiqaatAttendanceItem> items;

  MemberMiqaatAttendanceHistory({
    required this.memberId,
    required this.fullName,
    this.itsId,
    required this.totalPoints,
    required this.items,
  });

  factory MemberMiqaatAttendanceHistory.fromJson(Map<String, dynamic> json) {
    return MemberMiqaatAttendanceHistory(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String? ?? '',
      itsId: json['itsId'] as String?,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => MemberMiqaatAttendanceItem.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MemberMiqaatAttendanceItem {
  final int miqaatId;
  final String miqaatName;
  final DateTime fromDate;
  final DateTime tillDate;
  final int miqaatDays;
  final int miqaatDay;
  final bool isAttended;
  final int points;

  MemberMiqaatAttendanceItem({
    required this.miqaatId,
    required this.miqaatName,
    required this.fromDate,
    required this.tillDate,
    required this.miqaatDays,
    required this.miqaatDay,
    required this.isAttended,
    required this.points,
  });

  factory MemberMiqaatAttendanceItem.fromJson(Map<String, dynamic> json) {
    return MemberMiqaatAttendanceItem(
      miqaatId: (json['miqaatId'] as num?)?.toInt() ?? 0,
      miqaatName: json['miqaatName'] as String? ?? '',
      fromDate: DateTime.parse(json['fromDate'] as String),
      tillDate: DateTime.parse(json['tillDate'] as String),
      miqaatDays: (json['miqaatDays'] as num?)?.toInt() ?? 1,
      miqaatDay: (json['miqaatDay'] as num?)?.toInt() ?? 1,
      isAttended: json['isAttended'] as bool? ?? false,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  DateTime get dayDate => fromDate.add(Duration(days: miqaatDay - 1));
}
