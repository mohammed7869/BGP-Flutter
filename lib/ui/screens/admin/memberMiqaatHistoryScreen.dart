import 'dart:convert';

import 'package:burhaniguardsapp/core/constants/api_constants.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MemberMiqaatHistoryScreen extends StatefulWidget {
  final int memberId;
  final String fullName;
  final String? itsId;
  final int? miqaatId;

  const MemberMiqaatHistoryScreen({
    Key? key,
    required this.memberId,
    required this.fullName,
    this.itsId,
    this.miqaatId,
  }) : super(key: key);

  @override
  State<MemberMiqaatHistoryScreen> createState() =>
      _MemberMiqaatHistoryScreenState();
}

class _MemberMiqaatHistoryScreenState extends State<MemberMiqaatHistoryScreen> {
  final LocalStorageService _localStorage = LocalStorageService();
  bool _isLoading = true;
  String? _error;
  MemberMiqaatAttendanceHistoryDto? _history;

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

      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.getEnrolledMembers}/member/${widget.memberId}/attendance-history');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        String errorMessage = 'Failed to fetch attendance history.';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = errorBody['message'] as String? ?? errorMessage;
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      var history = MemberMiqaatAttendanceHistoryDto.fromJson(jsonResponse);

      if (widget.miqaatId != null) {
        final filteredItems = history.items
            .where((item) => item.miqaatId == widget.miqaatId)
            .toList();

        final filteredPoints =
            filteredItems.fold<int>(0, (sum, item) => sum + item.points);

        history = MemberMiqaatAttendanceHistoryDto(
          memberId: history.memberId,
          fullName: history.fullName,
          itsId: history.itsId,
          totalPoints: filteredPoints,
          items: filteredItems,
        );
      }

      if (!mounted) return;
      setState(() {
        _history = history;
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

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    return '$day $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Member History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.fullName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.itsId != null && widget.itsId!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'ITS ID: ${widget.itsId}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Total Points: ${_history?.totalPoints ?? 0}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Column(
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
                ),
              )
            else if ((_history?.items ?? []).isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    'No approved miqaat history found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              const Text(
                'Attendance History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ..._history!.items.map((item) {
                final statusColor =
                    item.isAttended ? Colors.green : Colors.red;
                final statusText = item.isAttended ? 'Attended' : 'Not Attended';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.isAttended
                            ? Icons.check_circle
                            : Icons.cancel_outlined,
                        color: statusColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.miqaatName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Day ${item.miqaatDay}/${item.miqaatDays} • ${_formatShortDate(item.dayDate)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$statusText • Points: ${item.points}',
                              style: TextStyle(
                                fontSize: 13,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class MemberMiqaatAttendanceHistoryDto {
  final int memberId;
  final String fullName;
  final String? itsId;
  final int totalPoints;
  final List<MemberMiqaatAttendanceItemDto> items;

  MemberMiqaatAttendanceHistoryDto({
    required this.memberId,
    required this.fullName,
    this.itsId,
    required this.totalPoints,
    required this.items,
  });

  factory MemberMiqaatAttendanceHistoryDto.fromJson(Map<String, dynamic> json) {
    return MemberMiqaatAttendanceHistoryDto(
      memberId: (json['memberId'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String? ?? '',
      itsId: json['itsId'] as String?,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => MemberMiqaatAttendanceItemDto.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MemberMiqaatAttendanceItemDto {
  final int miqaatId;
  final String miqaatName;
  final DateTime fromDate;
  final DateTime tillDate;
  final int miqaatDays;
  final int miqaatDay;
  final bool isAttended;
  final int points;

  MemberMiqaatAttendanceItemDto({
    required this.miqaatId,
    required this.miqaatName,
    required this.fromDate,
    required this.tillDate,
    required this.miqaatDays,
    required this.miqaatDay,
    required this.isAttended,
    required this.points,
  });

  factory MemberMiqaatAttendanceItemDto.fromJson(Map<String, dynamic> json) {
    return MemberMiqaatAttendanceItemDto(
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

