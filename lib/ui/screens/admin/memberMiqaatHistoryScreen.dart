import 'dart:convert';

import 'package:burhaniguardsapp/core/constants/api_constants.dart';
import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/utils/session_manager.dart';
import 'package:burhaniguardsapp/ui/screens/common/bohraCalendarScreen.dart';
import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

      if (response.statusCode == 401) {
        if (mounted) {
          SessionManager.handleSessionExpiry(
            context,
            onReLoginSuccess: _load,
          );
        }
        return;
      }

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

      if (SessionManager.isSessionExpired(e)) {
        setState(() {
          _isLoading = false;
        });
        SessionManager.handleSessionExpiry(
          context,
          onReLoginSuccess: _load,
        );
        return;
      }

      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    return '$day $month ${date.year}';
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      await _localStorage.clearAll();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const UnifiedLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Premium AppBar with Calendar + Logout
          SafeArea(
            bottom: false,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                          'assets/images/burhani guards logo.png',
                          height: 52),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_month_outlined,
                            color: Colors.white, size: 26),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BohraCalendarScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 26),
                        onPressed: () => _handleLogout(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Member info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.fullName.isNotEmpty
                                  ? widget.fullName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.fullName,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (widget.itsId != null &&
                                  widget.itsId!.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'ITS ID: ${widget.itsId}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total Points card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFB300).withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFFFB300).withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE65100),
                                Color(0xFFFF8F00)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE65100)
                                    .withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.stars_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Points',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_history?.totalPoints ?? 0}',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.red.withOpacity(0.6)),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if ((_history?.items ?? []).isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 56,
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No approved miqaat history found',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Section title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Attendance History',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_history!.items.length} records',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ..._history!.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isAttended = item.isAttended;

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration:
                            Duration(milliseconds: 400 + (index * 80)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 15 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isAttended
                                ? const Color(0xFFF0FAF0)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isAttended
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Status icon with gradient
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: isAttended
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF2E7D32),
                                              Color(0xFF43A047)
                                            ],
                                          )
                                        : const LinearGradient(
                                            colors: [
                                              Color(0xFFC62828),
                                              Color(0xFFE53935)
                                            ],
                                          ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isAttended
                                                ? Colors.green
                                                : Colors.red)
                                            .withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isAttended
                                        ? Icons.check_rounded
                                        : Icons.close_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.miqaatName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .calendar_today_rounded,
                                            size: 12,
                                            color:
                                                AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Day ${item.miqaatDay}/${item.miqaatDays} • ${_formatShortDate(item.dayDate)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: AppColors
                                                  .textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isAttended
                                                  ? const Color(
                                                      0xFFE8F5E9)
                                                  : const Color(
                                                      0xFFFFEBEE),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(8),
                                            ),
                                            child: Text(
                                              isAttended
                                                  ? 'Attended'
                                                  : 'Not Attended',
                                              style:
                                                  GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: isAttended
                                                    ? const Color(
                                                        0xFF2E7D32)
                                                    : const Color(
                                                        0xFFC62828),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                  0xFFFFF3E0),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.stars_rounded,
                                                  size: 12,
                                                  color: Color(
                                                      0xFFE65100),
                                                ),
                                                const SizedBox(
                                                    width: 3),
                                                Text(
                                                  '${item.points} pts',
                                                  style: GoogleFonts
                                                      .poppins(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600,
                                                    color:
                                                        const Color(
                                                            0xFFE65100),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
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
