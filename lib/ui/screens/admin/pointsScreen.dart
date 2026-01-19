import 'dart:convert';

import 'package:burhaniguardsapp/core/constants/api_constants.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/memberMiqaatHistoryScreen.dart';
import 'package:burhaniguardsapp/ui/widgets/adminAppBarforPages.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PointsScreen extends StatefulWidget {
  const PointsScreen({Key? key}) : super(key: key);

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  final LocalStorageService _localStorage = LocalStorageService();
  bool _isLoading = true;
  bool _isCaptain = false;
  String? _error;
  List<MemberPointsDto> _members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _localStorage.getToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final user = await _localStorage.getUserData();
      _isCaptain = user?.roles == 2;

      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.getMiqaatPoints}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        String errorMessage = 'Failed to fetch points.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'] as String? ?? errorMessage;
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      final members = data
          .map((item) => MemberPointsDto.fromJson(item as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          buildAppBarWithBackButton(context),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Points',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _error!,
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _load,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : _members.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No points found',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _load,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      itemCount: _members.length,
                                      itemBuilder: (context, index) {
                                        final member = _members[index];
                                        return _buildMemberCard(member);
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(MemberPointsDto member) {
    return InkWell(
      onTap: !_isCaptain
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberMiqaatHistoryScreen(
                    memberId: member.memberId,
                    fullName: member.fullName,
                    itsId: member.itsId,
                  ),
                ),
              );
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Icon(Icons.person, color: Colors.grey, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (member.itsId != null && member.itsId!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ITS ID: ${member.itsId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${member.totalPoints} pts',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MemberPointsDto {
  final int memberId;
  final String fullName;
  final String? itsId;
  final int totalPoints;

  MemberPointsDto({
    required this.memberId,
    required this.fullName,
    this.itsId,
    required this.totalPoints,
  });

  factory MemberPointsDto.fromJson(Map<String, dynamic> json) {
    return MemberPointsDto(
      memberId: (json['memberId'] as num?)?.toInt() ??
          (json['memberId'] as int? ?? 0),
      fullName: json['fullName'] as String? ?? '',
      itsId: json['itsId'] as String?,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
    );
  }
}
