import 'package:burhaniguardsapp/core/constants/api_constants.dart';
import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/constants/jamaat.dart';
import 'package:burhaniguardsapp/core/constants/member_rank.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/user_service.dart';
import 'package:burhaniguardsapp/core/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Hierarchy Screen
/// Shows organisational tree based on logged-in user's role:
///  - AssistantCommander / MajorCaptain / ResourceAdmin → jamaat capsules + full tree
///  - Captain → own jamaat members only
///  - Member  → ranks above them (no member listing)
class HierarchyScreen extends StatefulWidget {
  const HierarchyScreen({super.key});

  @override
  State<HierarchyScreen> createState() => _HierarchyScreenState();
}

class _HierarchyScreenState extends State<HierarchyScreen>
    with TickerProviderStateMixin {
  final LocalStorageService _localStorage = LocalStorageService();
  final UserService _userService = UserService();

  // User info
  int _userRoleId = MemberRank.member;
  String _userJamaat = '';
  String _userItsId = '';

  // Data
  List<Map<String, dynamic>> _allMembers = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Selected jamaat for admin/multi-jamaat view
  String _selectedJamaat = '';
  final List<String> _jamaatList = [];

  // Animations
  late AnimationController _headerController;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _loadData();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  bool get _isAdmin {
    return _userRoleId == MemberRank.assistantCommander ||
        _userRoleId == MemberRank.majorCaptain ||
        _userRoleId == MemberRank.resourceAdmin;
  }

  bool get _isCaptain {
    return _userRoleId == MemberRank.captain;
  }

  bool get _isMember {
    return _userRoleId == MemberRank.member;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await _localStorage.getUserData();
      if (userData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User data not found. Please login again.';
        });
        return;
      }

      final roleId =
          MemberRank.getRoleId(userData.rank) ?? userData.roles ?? MemberRank.member;
      final jamaat = userData.jamaat ?? '';
      
      setState(() {
        _userRoleId = roleId;
        _userJamaat = jamaat;
        _userItsId = userData.itsId ?? '';
      });

      if (_isAdmin) {
        // Build jamaat list from constants
        _jamaatList.clear();
        for (var j in Jamaat.jamaatList) {
          _jamaatList.add(j.text);
        }
        // Set the selected jamaat – prefer user's own jamaat if it exists
        _selectedJamaat =
            _jamaatList.contains(jamaat) ? jamaat : (_jamaatList.isNotEmpty ? _jamaatList.first : '');
        await _loadMembersForJamaat(_selectedJamaat);
      } else {
        // Captain or Member – load their own jamaat only
        _selectedJamaat = jamaat;
        await _loadMembersForJamaat(jamaat);
      }

      _headerController.forward();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _loadMembersForJamaat(String jamaat) async {
    if (jamaat.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final members = await _userService.getHierarchyMembers(jamaat);
      setState(() {
        _allMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(dynamic e) {
    if (!mounted) return;
    if (SessionManager.isSessionExpired(e)) {
      if (!mounted) return;
      SessionManager.handleSessionExpiry(context, onReLoginSuccess: _loadData);
      return;
    }
    setState(() {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    });
  }

  // ── Helpers ──

  /// Build the profile image URL
  String _getProfileUrl(String? profile) {
    if (profile == null || profile.isEmpty) return '';
    if (profile.startsWith('http')) return profile;
    if (profile.startsWith('bgp_uploads')) {
      return '${ApiConstants.baseUrl}/$profile';
    }
    // ITS ID image
    return '${ApiConstants.baseUrl}/bgp_uploads/profile/$profile';
  }

  /// Group members by role ID, sorted by hierarchy (highest first)
  Map<int, List<Map<String, dynamic>>> _groupByRole(
      List<Map<String, dynamic>> members) {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (var m in members) {
      final roleId = (m['roles'] as int?) ??
          MemberRank.getRoleId(m['rank']?.toString()) ??
          MemberRank.member;

      // When Member is logged in, they see only themselves at the Member rank level
      if (_isMember && roleId == MemberRank.member) {
        final itsId = m['its_id']?.toString() ?? m['itsId']?.toString();
        if (itsId != _userItsId) {
          continue; // Skip other members of the same jamaat
        }
      }

      grouped.putIfAbsent(roleId, () => []).add(m);
    }
    return grouped;
  }

  /// Rank order for the tree (top to bottom)
  static const _rankOrder = [
    MemberRank.assistantCommander,
    MemberRank.majorCaptain,
    MemberRank.resourceAdmin,
    MemberRank.captain,
    MemberRank.viceCaptain,
    MemberRank.groupLeader,
    MemberRank.asstGroupLeader,
    MemberRank.member,
  ];

  // ──────────────────────── BUILD  ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            if (_isAdmin && _jamaatList.isNotEmpty) _buildJamaatCapsules(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: AppColors.headerShadow,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: FadeTransition(
              opacity: _headerFade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hierarchy',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (_selectedJamaat.isNotEmpty)
                    Text(
                      _selectedJamaat,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_tree_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Jamaat Capsules ──
  Widget _buildJamaatCapsules() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppColors.surface,
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _jamaatList.length,
          itemBuilder: (context, index) {
            final jamaat = _jamaatList[index];
            final isSelected = jamaat == _selectedJamaat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () async {
                  setState(() => _selectedJamaat = jamaat);
                  await _loadMembersForJamaat(jamaat);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryDark
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.divider,
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primaryDark.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    _formatJamaatLabel(jamaat),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatJamaatLabel(String raw) {
    // Shorten "FAKHRI MOHALLA (POONA)" → "Fakhri Mohalla"
    var label = raw.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();
    // Title case
    label = label
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
        .join(' ');
    return label;
  }

  // ── Body ──
  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text('Loading hierarchy…',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_allMembers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadMembersForJamaat(_selectedJamaat),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: _buildHierarchyTree(),
      ),
    );
  }

  // ── Hierarchy Tree ──
  Widget _buildHierarchyTree() {
    final grouped = _groupByRole(_allMembers);

    // Show all ranks. Filtering for Member (seeing only themselves) is handled in _groupByRole
    List<int> visibleRanks = List.from(_rankOrder);

    // Only show ranks that have members
    final activeRanks = visibleRanks.where((r) => grouped.containsKey(r)).toList();

    if (activeRanks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        for (int i = 0; i < activeRanks.length; i++) ...[
          _buildRankLevel(
            rankId: activeRanks[i],
            members: grouped[activeRanks[i]]!,
            isLast: i == activeRanks.length - 1,
          ),
          if (i < activeRanks.length - 1) _buildConnector(),
        ],
        // For Captain: show member count footer
        if (_isCaptain && grouped.containsKey(MemberRank.member))
          _buildMemberCountFooter(grouped[MemberRank.member]!.length),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Rank Level ──
  Widget _buildRankLevel({
    required int rankId,
    required List<Map<String, dynamic>> members,
    bool isLast = false,
  }) {
    final rankText = MemberRank.getRankText(rankId);
    final rankColor = _getRankColor(rankId);

    // If only 1 member, show single card
    if (members.length == 1) {
      return _buildHierarchyCard(
        member: members.first,
        rankText: rankText,
        rankColor: rankColor,
        rankId: rankId,
      );
    }

    // Multiple members at the same level – show them side by side with branching
    return Column(
      children: [
        // Rank label
        _buildRankBadge(rankText, rankColor),
        const SizedBox(height: 10),
        // Branch connector
        if (members.length > 1) _buildBranchTop(members.length),
        // Member cards
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: members
                .map((m) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _buildMemberAvatar(
                        member: m,
                        rankColor: rankColor,
                        rankId: rankId,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Single Hierarchy Card (for single member at a level) ──
  Widget _buildHierarchyCard({
    required Map<String, dynamic> member,
    required String rankText,
    required Color rankColor,
    required int rankId,
  }) {
    final fullName = member['fullName']?.toString() ?? member['full_name']?.toString() ?? 'Unknown';
    final profile = member['profile']?.toString();
    final profileUrl = _getProfileUrl(profile);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: rankColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: rankColor.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile photo
            _buildProfileCircle(profileUrl, rankColor, 52),
            const SizedBox(width: 14),
            // Name + Rank
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildRankBadge(rankText, rankColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Member Avatar (for multiple members at the same level) ──
  Widget _buildMemberAvatar({
    required Map<String, dynamic> member,
    required Color rankColor,
    required int rankId,
  }) {
    final fullName = member['fullName']?.toString() ?? member['full_name']?.toString() ?? 'Unknown';
    final profile = member['profile']?.toString();
    final profileUrl = _getProfileUrl(profile);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
        );
      },
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: rankColor.withOpacity(0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: rankColor.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildProfileCircle(profileUrl, rankColor, 48),
            const SizedBox(height: 8),
            Text(
              fullName,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile Circle ──
  Widget _buildProfileCircle(String url, Color borderColor, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(size),
              )
            : _buildPlaceholder(size),
      ),
    );
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      color: AppColors.accent,
      child: Icon(Icons.person, color: AppColors.primaryLight, size: size * 0.5),
    );
  }

  // ── Rank Badge ──
  Widget _buildRankBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Connector (vertical line between levels) ──
  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        children: [
          Container(
            width: 2.5,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.4),
                  AppColors.primary.withOpacity(0.15),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppColors.primary.withOpacity(0.4)),
        ],
      ),
    );
  }

  // ── Branch connector for multiple members ──
  Widget _buildBranchTop(int count) {
    return SizedBox(
      height: 18,
      child: CustomPaint(
        size: Size(count * 130.0, 18),
        painter: _BranchPainter(
          color: AppColors.primary.withOpacity(0.25),
          count: count,
        ),
      ),
    );
  }

  // ── Member count footer (for captains) ──
  Widget _buildMemberCountFooter(int count) {
    return Column(
      children: [
        _buildConnector(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryLight.withOpacity(0.08),
                AppColors.primaryDark.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.groups_rounded,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                '$count Members',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Empty state ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined,
              size: 64, color: AppColors.primary.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No hierarchy data found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No members found for this jamaat',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ──
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.error.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('Retry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rank colors ──
  Color _getRankColor(int rankId) {
    switch (rankId) {
      case MemberRank.assistantCommander:
        return const Color(0xFF6B2F26); // Deep maroon
      case MemberRank.resourceAdmin:
        return const Color(0xFF01579B); // Deep blue
      case MemberRank.majorCaptain:
        return const Color(0xFF2E7D32); // Forest green
      case MemberRank.captain:
        return const Color(0xFFE67E22); // Orange
      case MemberRank.viceCaptain:
        return const Color(0xFF8E44AD); // Purple
      case MemberRank.groupLeader:
        return const Color(0xFF0D7377); // Teal
      case MemberRank.asstGroupLeader:
        return const Color(0xFF7B1FA2); // Deep purple
      case MemberRank.member:
        return const Color(0xFF546E7A); // Blue grey
      default:
        return AppColors.primary;
    }
  }
}

// ── Custom painter for branch lines ──
class _BranchPainter extends CustomPainter {
  final Color color;
  final int count;

  _BranchPainter({required this.color, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = size.width / 2;
    const cardWidth = 130.0;
    final totalWidth = count * cardWidth;
    final startX = center - totalWidth / 2 + cardWidth / 2;

    // Draw vertical line from top center
    canvas.drawLine(Offset(center, 0), Offset(center, 10), paint);

    // Draw horizontal line
    final endX = startX + (count - 1) * cardWidth;
    canvas.drawLine(Offset(startX, 10), Offset(endX, 10), paint);

    // Draw vertical ticks down to each card
    for (int i = 0; i < count; i++) {
      final x = startX + i * cardWidth;
      canvas.drawLine(Offset(x, 10), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
