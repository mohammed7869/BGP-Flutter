import 'dart:convert';

import 'package:burhaniguardsapp/core/constants/api_constants.dart';
import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/utils/session_manager.dart';
import 'package:burhaniguardsapp/ui/screens/admin/memberMiqaatHistoryScreen.dart';
import 'package:burhaniguardsapp/ui/widgets/adminAppBarforPages.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class PointsScreen extends StatefulWidget {
  const PointsScreen({Key? key}) : super(key: key);

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen>
    with SingleTickerProviderStateMixin {
  final LocalStorageService _localStorage = LocalStorageService();
  bool _isLoading = true;
  bool _isCaptain = false;
  int? _currentUserId;
  String? _error;
  List<MemberPointsDto> _members = [];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      _isCaptain = (user?.roles == 2 || user?.roles == 6);
      _currentUserId = user?.id;

      final url =
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getMiqaatPoints}');
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
      var members = data
          .map((item) => MemberPointsDto.fromJson(item as Map<String, dynamic>))
          .toList();

      if (_isCaptain) {
        members.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      }

      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoading = false;
      });

      _animationController.forward();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          buildAppBarWithBackButton(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title section with icon badge
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE65100).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCaptain ? 'Leaderboard' : 'My Points',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _isCaptain
                                ? '${_members.length} members ranked'
                                : 'Your performance tracker',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 3,
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                            )
                          : _members.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.stars_rounded,
                                        size: 56,
                                        color:
                                            AppColors.primary.withOpacity(0.2),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No points found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _load,
                                  color: AppColors.primary,
                                  child: _isCaptain
                                      ? _buildCaptainView()
                                      : _buildMemberView(),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptainView() {
    final topMembers = _members.take(3).toList();
    final otherMembers = _members.skip(3).toList();

    final pointsCount = <int, int>{};
    for (final member in _members) {
      pointsCount[member.totalPoints] =
          (pointsCount[member.totalPoints] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (topMembers.isNotEmpty) _buildPodiumSection(topMembers, pointsCount),
        const SizedBox(height: 24),
        if (otherMembers.isNotEmpty) ...[
          Text(
            'Other Members',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...otherMembers.asMap().entries.map((entry) {
            final hasSamePoints =
                (pointsCount[entry.value.totalPoints] ?? 0) > 1;
            return _buildMemberCard(entry.value,
                rank: entry.key + 4, hasSamePoints: hasSamePoints);
          }),
        ],
      ],
    );
  }

  Widget _buildMemberView() {
    if (_members.isEmpty) {
      return Center(
        child: Text(
          'No points data available',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      );
    }

    final sortedMembers = List<MemberPointsDto>.from(_members);
    sortedMembers.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    int userRank = 1;
    for (int i = 0; i < sortedMembers.length; i++) {
      if (sortedMembers[i].memberId == _currentUserId) {
        userRank = i + 1;
        break;
      }
    }

    final currentUserData = _members.firstWhere(
      (m) => m.memberId == _currentUserId,
      orElse: () => _members.first,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildMemberCard(currentUserData, rank: userRank),
      ],
    );
  }

  Widget _buildPodiumSection(
      List<MemberPointsDto> topMembers, Map<int, int> pointsCount) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '🏆 Top Performers 🏆',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (topMembers.length > 1)
                  _buildPodiumItem(topMembers[1], 2, 80,
                      isTied:
                          (pointsCount[topMembers[1].totalPoints] ?? 0) > 1)
                else
                  const SizedBox(width: 90),
                const SizedBox(width: 8),
                if (topMembers.isNotEmpty)
                  _buildPodiumItem(topMembers[0], 1, 100,
                      isTied:
                          (pointsCount[topMembers[0].totalPoints] ?? 0) > 1),
                const SizedBox(width: 8),
                if (topMembers.length > 2)
                  _buildPodiumItem(topMembers[2], 3, 60,
                      isTied:
                          (pointsCount[topMembers[2].totalPoints] ?? 0) > 1)
                else
                  const SizedBox(width: 90),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumItem(MemberPointsDto member, int rank, double height,
      {bool isTied = false}) {
    final colors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    final icons = {
      1: '🥇',
      2: '🥈',
      3: '🥉',
    };

    return GestureDetector(
      onTap: () {
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
      child: Column(
        children: [
          Text(
            icons[rank] ?? '',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Container(
            width: rank == 1 ? 60 : 50,
            height: rank == 1 ? 60 : 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors[rank]!,
                  colors[rank]!.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[rank]!.withOpacity(0.5),
                  blurRadius: rank == 1 ? 15 : 10,
                  spreadRadius: rank == 1 ? 3 : 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                member.fullName.isNotEmpty
                    ? member.fullName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.poppins(
                  fontSize: rank == 1 ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 90,
            child: Text(
              member.fullName,
              style: GoogleFonts.poppins(
                fontSize: rank == 1 ? 13 : 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors[rank],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors[rank]!.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${member.totalPoints} pts',
              style: GoogleFonts.poppins(
                fontSize: rank == 1 ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: rank == 1 ? Colors.black87 : Colors.white,
              ),
            ),
          ),
          if (isTied)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'TIE',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            width: 90,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors[rank]!.withOpacity(0.8),
                  colors[rank]!.withOpacity(0.5),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(MemberPointsDto member,
      {int? rank, bool hasSamePoints = false}) {
    final isCurrentUser = member.memberId == _currentUserId;

    return InkWell(
      onTap: () {
        if (_isCaptain || isCurrentUser) {
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
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasSamePoints && !isCurrentUser
              ? const Color(0xFFFFF8E1)
              : isCurrentUser
                  ? const Color(0xFFFFF8E1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSamePoints
                ? Colors.orange.withOpacity(0.6)
                : isCurrentUser
                    ? const Color(0xFFFFB300)
                    : Colors.grey.withOpacity(0.12),
            width: (isCurrentUser || hasSamePoints) ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCurrentUser
                  ? const Color(0xFFFFB300).withOpacity(0.2)
                  : hasSamePoints
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (rank != null) ...[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: isCurrentUser
                      ? const LinearGradient(
                          colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                        )
                      : null,
                  color: isCurrentUser ? null : AppColors.background,
                  shape: BoxShape.circle,
                  border: isCurrentUser
                      ? null
                      : Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? const LinearGradient(
                        colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primaryLight.withOpacity(0.05),
                        ],
                      ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentUser
                      ? Colors.transparent
                      : Colors.grey.withOpacity(0.15),
                ),
              ),
              child: Icon(
                Icons.person_rounded,
                color: isCurrentUser ? Colors.white : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.fullName,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isCurrentUser
                                ? const Color(0xFFE65100)
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'You',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (member.itsId != null && member.itsId!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'ITS ID: ${member.itsId}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasSamePoints)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'TIE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                      )
                    : null,
                color: isCurrentUser ? null : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isCurrentUser
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE65100).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    size: 14,
                    color:
                        isCurrentUser ? Colors.white : const Color(0xFFE65100),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${member.totalPoints}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser
                          ? Colors.white
                          : const Color(0xFFE65100),
                    ),
                  ),
                ],
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
