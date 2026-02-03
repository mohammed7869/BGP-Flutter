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
      _isCaptain = user?.roles == 2;
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

      // Sort by points descending for captain view
      if (_isCaptain) {
        members.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      }

      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoading = false;
      });

      // Start animation after data loads
      _animationController.forward();
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
              decoration: BoxDecoration(
                gradient: _isCaptain
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFFBF5), Colors.white],
                      )
                    : null,
                color: _isCaptain ? null : Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Color(0xFFE65100), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          _isCaptain ? 'Leaderboard' : 'My Points',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
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
                                    child: _isCaptain
                                        ? _buildCaptainView()
                                        : _buildMemberView(),
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

  Widget _buildCaptainView() {
    final topMembers = _members.take(3).toList();
    final otherMembers = _members.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Top 3 Podium Section
        if (topMembers.isNotEmpty) _buildPodiumSection(topMembers),
        const SizedBox(height: 24),
        if (otherMembers.isNotEmpty) ...[
          const Text(
            'Other Members',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...otherMembers.asMap().entries.map((entry) {
            return _buildMemberCard(entry.value, rank: entry.key + 4);
          }),
        ],
      ],
    );
  }

  Widget _buildMemberView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return _buildMemberCard(member);
      },
    );
  }

  Widget _buildPodiumSection(List<MemberPointsDto> topMembers) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A1C1C), Color(0xFF6D2E2E)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A1C1C).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              '🏆 Top Performers 🏆',
              style: TextStyle(
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
                // 2nd Place
                if (topMembers.length > 1)
                  _buildPodiumItem(topMembers[1], 2, 80)
                else
                  const SizedBox(width: 90),
                const SizedBox(width: 8),
                // 1st Place
                if (topMembers.isNotEmpty) _buildPodiumItem(topMembers[0], 1, 100),
                const SizedBox(width: 8),
                // 3rd Place
                if (topMembers.length > 2)
                  _buildPodiumItem(topMembers[2], 3, 60)
                else
                  const SizedBox(width: 90),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumItem(MemberPointsDto member, int rank, double height) {
    final colors = {
      1: const Color(0xFFFFD700), // Gold
      2: const Color(0xFFC0C0C0), // Silver
      3: const Color(0xFFCD7F32), // Bronze
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
          // Medal icon
          Text(
            icons[rank] ?? '',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 4),
          // Avatar with glow
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
                style: TextStyle(
                  fontSize: rank == 1 ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Name
          SizedBox(
            width: 90,
            child: Text(
              member.fullName,
              style: TextStyle(
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
          // Points badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors[rank],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${member.totalPoints} pts',
              style: TextStyle(
                fontSize: rank == 1 ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: rank == 1 ? Colors.black87 : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Podium bar
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
                style: TextStyle(
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

  Widget _buildMemberCard(MemberPointsDto member, {int? rank}) {
    final isCurrentUser = member.memberId == _currentUserId;

    return InkWell(
      onTap: () {
        // Navigate for both captain and member (if it's their own data)
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
          color: isCurrentUser ? const Color(0xFFFFF8E1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentUser ? const Color(0xFFFFB300) : Colors.grey[300]!,
            width: isCurrentUser ? 2 : 1,
          ),
          boxShadow: isCurrentUser
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            if (rank != null) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? const LinearGradient(
                        colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                      )
                    : null,
                color: isCurrentUser ? null : const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentUser ? Colors.transparent : Colors.grey[300]!,
                ),
              ),
              child: Icon(
                Icons.person,
                color: isCurrentUser ? Colors.white : Colors.grey,
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isCurrentUser
                                ? const Color(0xFFE65100)
                                : Colors.black87,
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
                            color: const Color(0xFFE65100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
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
                    const SizedBox(height: 4),
                    Text(
                      'ITS ID: ${member.itsId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars,
                    size: 14,
                    color: isCurrentUser ? Colors.white : const Color(0xFFE65100),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${member.totalPoints}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isCurrentUser ? Colors.white : const Color(0xFFE65100),
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
