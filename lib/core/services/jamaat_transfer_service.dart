import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'local_storage_service.dart';

class JamaatTransferService {
  final LocalStorageService _storageService = LocalStorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> initiateTransfer(int memberId, int toJamaatId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.initiateTransfer}'),
      headers: headers,
      body: jsonEncode({
        'memberId': memberId,
        'toJamaatId': toJamaatId,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to initiate transfer');
    }
  }

  Future<List<dynamic>> getPendingOutgoingTransfers(int jamaatId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getPendingOutgoingTransfers}/$jamaatId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch outgoing transfers');
    }
  }

  Future<List<dynamic>> getPendingIncomingTransfers(int jamaatId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getPendingIncomingTransfers}/$jamaatId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch incoming transfers');
    }
  }

  Future<List<dynamic>> getHistoryTransfers(int jamaatId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getHistoryTransfers}/$jamaatId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch history transfers');
    }
  }

  Future<void> acceptTransfer(int id) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.acceptTransfer}/$id/accept'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to accept transfer');
    }
  }

  Future<void> rejectTransfer(int id, String reason) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rejectTransfer}/$id/reject'),
      headers: headers,
      body: jsonEncode({'reason': reason}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to reject transfer');
    }
  }
}
