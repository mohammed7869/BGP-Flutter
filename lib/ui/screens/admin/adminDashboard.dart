
import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:burhaniguardsapp/core/services/user_service.dart';
import 'package:burhaniguardsapp/core/utils/session_manager.dart';
import 'package:burhaniguardsapp/ui/screens/admin/attendancemiqaatScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/createMiqaatScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/membersListScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/pointsScreen.dart';
import 'package:burhaniguardsapp/ui/screens/common/underDevelopmentScreen.dart';
import 'package:burhaniguardsapp/ui/widgets/adminAppBar.dart';
import 'package:burhaniguardsapp/ui/widgets/adminAppDrawer.dart';
import 'package:burhaniguardsapp/ui/widgets/adminBottomNavigationBar.dart';
import 'package:burhaniguardsapp/ui/screens/common/hierarchyScreen.dart';
import 'package:burhaniguardsapp/ui/widgets/survey_popup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final MiqaatService _miqaatService = MiqaatService();
  final LocalStorageService _localStorage = LocalStorageService();
  final UserService _userService = UserService();
  List<Miqaat> _memberMiqaats = [];
  bool _isLoadingMiqaats = false;
  int _selectedMiqaatTab = 0; // 0=Ongoing, 1=Upcoming, 2=Completed

  // ── Role & counts for Quick Actions ──
  bool _isCaptain = false;
  int _memberCount = 0;
  int _miqaatCount = 0;
  int _totalPoints = 0;

  // ── Animations ──
  late AnimationController _shortcutController;
  late AnimationController _miqaatController;
  late Animation<double> _shortcutFade;
  late Animation<Offset> _shortcutSlide;
  late Animation<double> _miqaatFade;
  late Animation<Offset> _miqaatSlide;

  @override
  void initState() {
    super.initState();

    _shortcutController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _shortcutFade = CurvedAnimation(
      parent: _shortcutController,
      curve: Curves.easeOut,
    );
    _shortcutSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _shortcutController,
      curve: Curves.easeOutCubic,
    ));

    _miqaatController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _miqaatFade = CurvedAnimation(
      parent: _miqaatController,
      curve: Curves.easeOut,
    );
    _miqaatSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _miqaatController,
      curve: Curves.easeOutCubic,
    ));

    // Stagger entrance
    _shortcutController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _miqaatController.forward();
    });

    _loadMemberMiqaats();
    _loadUserRoleAndCounts();

    // --- Khidmat Survey has been stopped (Ashara Mubaraka Poona 1448) ---
    // Survey popup disabled on dashboard load
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Future.delayed(const Duration(milliseconds: 800), () {
    //     if (mounted) {
    //       debugPrint('[Survey] Checking survey popup...');
    //       SurveyPopup.showIfNeeded(context);
    //     }
    //   });
    // });
  }

  Future<void> _loadUserRoleAndCounts() async {
    try {
      final userData = await _localStorage.getUserData();
      if (userData == null) return;
      final isCaptain = userData.roles == 2;
      setState(() => _isCaptain = isCaptain);

      if (isCaptain) {
        // Load member count for the captain's jamaat
        if (userData.jamaat != null && userData.jamaat!.isNotEmpty) {
          try {
            final members = await _userService.getMembersByJamaat(userData.jamaat!);
            if (mounted) setState(() => _memberCount = members.length);
          } catch (_) {}
        }
        // Miqaat count = total miqaats loaded for this jamaat
        if (mounted) setState(() => _miqaatCount = _memberMiqaats.length);
      } else {
        // Member: load their total points
        if (mounted) setState(() => _miqaatCount = _memberMiqaats.length);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _shortcutController.dispose();
    _miqaatController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberMiqaats() async {
    setState(() {
      _isLoadingMiqaats = true;
    });

    try {
      final userData = await _localStorage.getUserData();
      if (userData != null && userData.id > 0) {
        // Captains: show miqaats of their own jamaat from all miqaats
        // Members: show assigned miqaats, filtered to their jamaat for safety
        List<Miqaat> miqaats;
        if (userData.roles == 2) {
          miqaats = await _miqaatService.getAllMiqaats();
        } else {
          miqaats = await _miqaatService.getMemberMiqaats(userData.id);
        }

        if (userData.jamaat != null && userData.jamaat!.isNotEmpty) {
          final jamaatLower = userData.jamaat!.toLowerCase();
          miqaats = miqaats.where((m) {
            if (m.isInternational) {
              if (m.jamaat.trim().isEmpty) return true;
              return m.jamaat.toLowerCase().split(',').map((e) => e.trim()).contains(jamaatLower);
            }
            return m.jamaat.toLowerCase().split(',').map((e) => e.trim()).contains(jamaatLower);
          }).toList();
        }

        setState(() {
          _memberMiqaats = miqaats;
          _isLoadingMiqaats = false;
          _miqaatCount = miqaats.length;
        });
      } else {
        setState(() {
          _isLoadingMiqaats = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMiqaats = false;
      });
      if (mounted) {
        // Check for session expiry
        if (SessionManager.isSessionExpired(e)) {
          SessionManager.handleSessionExpiry(
            context,
            onReLoginSuccess: _loadMemberMiqaats,
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load miqaats: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Miqaat categorization ──
  bool _isMiqaatOngoing(Miqaat miqaat) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = DateTime(miqaat.fromDate.year, miqaat.fromDate.month, miqaat.fromDate.day);
    final till = DateTime(miqaat.tillDate.year, miqaat.tillDate.month, miqaat.tillDate.day);
    return !today.isBefore(from) && !today.isAfter(till);
  }

  bool _isMiqaatUpcoming(Miqaat miqaat) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = DateTime(miqaat.fromDate.year, miqaat.fromDate.month, miqaat.fromDate.day);
    return today.isBefore(from);
  }

  // _isMiqaatCompleted already exists

  List<Miqaat> get _filteredMiqaats {
    switch (_selectedMiqaatTab) {
      case 0:
        return _memberMiqaats.where((m) => _isMiqaatOngoing(m)).toList();
      case 1:
        return _memberMiqaats.where((m) => _isMiqaatUpcoming(m)).toList();
      case 2:
        return _memberMiqaats.where((m) => _isMiqaatCompleted(m.tillDate)).toList();
      default:
        return _memberMiqaats;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      key: scaffoldKey,
      drawer: const AdminAppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            buildAppBar(context, scaffoldKey),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    SlideTransition(
                      position: _shortcutSlide,
                      child: FadeTransition(
                        opacity: _shortcutFade,
                        child: _buildShortcuts(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SlideTransition(
                      position: _miqaatSlide,
                      child: FadeTransition(
                        opacity: _miqaatFade,
                        child: _buildMiqaatSection(),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBarCaptain(),
    );
  }

  Widget _buildShortcuts() {
    void onShortCutTap(int route) {
      if (route == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MembersListScreen()),
        );
      } else if (route == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const AttendanceMiqaatScreen()),
        );
      } else if (route == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PointsScreen()),
        );
      } else if (route == 4) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const UnderDevelopmentScreen(title: 'Qardan Hasana')),
        );
      } else if (route == 5) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HierarchyScreen()),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (_isCaptain)
            // Captain: Members + Miqaats + Leaderboard (3 compact cards)
            Row(
              children: [
                Expanded(
                  child: _buildShortcutCard(
                    icon: Icons.people_alt_rounded,
                    label: 'Members',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D7377), Color(0xFF14BDAC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    glowColor: const Color(0xFF0D7377),
                    onTap: () => onShortCutTap(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShortcutCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'Miqaats',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE67E22), Color(0xFFF5B041)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    glowColor: const Color(0xFFE67E22),
                    onTap: () => onShortCutTap(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShortcutCard(
                    icon: Icons.leaderboard_rounded,
                    label: 'Leaderboard',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E44AD), Color(0xFFBB6BD9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    glowColor: const Color(0xFF8E44AD),
                    onTap: () => onShortCutTap(3),
                  ),
                ),
              ],
            )
          else
            // Member: Miqaats + My Points + Qardan Hasana (3 compact cards)
            Row(
              children: [
                Expanded(
                  child: _buildShortcutCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'Miqaats',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE67E22), Color(0xFFF5B041)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    glowColor: const Color(0xFFE67E22),
                    onTap: () => onShortCutTap(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShortcutCard(
                    icon: Icons.stars_rounded,
                    label: 'My Points',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8E44AD), Color(0xFFBB6BD9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    glowColor: const Color(0xFF8E44AD),
                    onTap: () => onShortCutTap(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShortcutCard(
                    icon: Icons.account_tree_rounded,
                    label: 'Hierarchy',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    glowColor: const Color(0xFF2E7D32),
                    onTap: () => onShortCutTap(5),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
    required Color glowColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.35),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiqaatCapsules() {
    final ongoingCount = _memberMiqaats.where((m) => _isMiqaatOngoing(m)).length;
    final upcomingCount = _memberMiqaats.where((m) => _isMiqaatUpcoming(m)).length;
    final completedCount = _memberMiqaats.where((m) => _isMiqaatCompleted(m.tillDate)).length;

    return Row(
      children: [
        _buildMiqaatCapsule(0, 'Ongoing', ongoingCount, const Color(0xFF2E7D32)),
        const SizedBox(width: 6),
        _buildMiqaatCapsule(1, 'Upcoming', upcomingCount, Colors.orange),
        const SizedBox(width: 6),
        _buildMiqaatCapsule(2, 'Completed', completedCount, AppColors.primary),
      ],
    );
  }

  Widget _buildMiqaatCapsule(int index, String label, int count, Color dotColor) {
    final isSelected = _selectedMiqaatTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMiqaatTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primaryDark : Colors.grey[300]!,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryDark.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '$label ($count)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiqaatSection() {
    final filteredList = _filteredMiqaats;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Miqaat',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingMiqaats)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
            )
          else if (_memberMiqaats.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.08),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 48,
                    color: AppColors.primary.withOpacity(0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No miqaats found',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else ...
            [
              // Capsule filters
              _buildMiqaatCapsules(),
              const SizedBox(height: 14),
              if (filteredList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 40,
                        color: AppColors.primary.withOpacity(0.25),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedMiqaatTab == 0
                            ? 'No ongoing miqaats'
                            : _selectedMiqaatTab == 1
                                ? 'No upcoming miqaats'
                                : 'No completed miqaats',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filteredList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final miqaat = entry.value;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 500 + (index * 120)),
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
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildMiqaatCard(
                        miqaat: miqaat,
                        title: miqaat.miqaatName,
                        dateRange: _formatDateRange(miqaat.fromDate, miqaat.tillDate, miqaat.miqaatDays),
                        location: miqaat.isInternational
                            ? 'International Miqaat'
                            : miqaat.isMultiJamaatLocal
                                ? 'Admin Local Miqaat (Multi-Jamaat)'
                                : '${miqaat.jamaat}, ${miqaat.jamiyat}',
                      ),
                    ),
                  );
                }),
            ],
        ],
      ),
    );
  }

  String _formatDateRange(DateTime from, DateTime till, int days) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dayLabel = '$days Day${days == 1 ? '' : 's'}';
    if (from.year == till.year && from.month == till.month) {
      // Same month + year: "18 - 28 Feb 2026 (11 Days)"
      return '${from.day} - ${till.day} ${months[from.month - 1]} ${from.year} ($dayLabel)';
    } else if (from.year == till.year) {
      // Same year, different month: "28 Feb - 5 Mar 2026 (6 Days)"
      return '${from.day} ${months[from.month - 1]} - ${till.day} ${months[till.month - 1]} ${from.year} ($dayLabel)';
    } else {
      // Different years: "28 Dec 2025 - 5 Jan 2026 (9 Days)"
      return '${from.day} ${months[from.month - 1]} ${from.year} - ${till.day} ${months[till.month - 1]} ${till.year} ($dayLabel)';
    }
  }

  bool _isMiqaatCompleted(DateTime tillDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(tillDate.year, tillDate.month, tillDate.day);
    return today.isAfter(end);
  }

  Widget _buildMiqaatCard({
    required Miqaat miqaat,
    required String title,
    required String dateRange,
    required String location,
  }) {
    final isCompleted = _isMiqaatCompleted(miqaat.tillDate);

    return Container(
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFE8F5E9)
            : miqaat.isInternational
                ? AppColors.internationalGoldLight
                : miqaat.isMultiJamaatLocal
                    ? const Color(0xFFE0F2F1)
                    : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: miqaat.isInternational
            ? Border.all(color: AppColors.internationalGold, width: 1.5)
            : miqaat.isMultiJamaatLocal
                ? Border.all(color: const Color(0xFF00897B).withOpacity(0.5), width: 1.5)
                : Border.all(color: Colors.grey.withOpacity(0.10), width: 1),
        boxShadow: [
          BoxShadow(
            color: miqaat.isInternational
                ? AppColors.internationalGold.withOpacity(0.20)
                : miqaat.isMultiJamaatLocal
                    ? const Color(0xFF00897B).withOpacity(0.15)
                    : Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  dateRange,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (miqaat.isInternational) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.internationalGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🌍 International',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    if (miqaat.isMultiJamaatLocal) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF00897B), Color(0xFF26A69A)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '📍 Admin',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    if (!miqaat.isInternational && !miqaat.isMultiJamaatLocal) const SizedBox(width: 6),
                    if (miqaat.isInternational || miqaat.isMultiJamaatLocal) const SizedBox(width: 6),
                    _buildStatusIcon(miqaat),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Action button strip ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: miqaat.isInternational
                  ? const LinearGradient(
                      colors: [Color(0xFFB8860B), Color(0xFFDAA520)],
                    )
                  : miqaat.isMultiJamaatLocal
                      ? const LinearGradient(
                          colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                        )
                      : AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: InkWell(
                child: FutureBuilder(
                    future: _localStorage.getUserData(),
                    builder: (context, snapshot) {
                      final isCaptain = snapshot.data?.roles == 2;

                      String buttonText = isCaptain
                          ? 'View Members List'
                          : 'View Day-wise Status';
                      bool enableTap = true;

                      if (_isMiqaatCompleted(miqaat.tillDate) && !isCaptain) {
                        buttonText = 'Miqaat Completed';
                        enableTap = false;
                      }

                      return InkWell(
                        onTap: !enableTap
                            ? null
                            : () async {
                                final userData = snapshot.data ??
                                    await _localStorage.getUserData();
                                final isCaptainTap = userData?.roles == 2;

                                if (isCaptainTap) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MembersListScreen(miqaat: miqaat),
                                    ),
                                  );
                                } else {
                                  _showDayWiseEnrollmentDialog(miqaat);
                                }
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              buttonText,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (enableTap) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white70,
                                size: 14,
                              ),
                            ],
                          ],
                        ),
                      );
                    })),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(Miqaat miqaat) {
    return FutureBuilder(
      future: _localStorage.getUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data;
        final isCaptain = userData?.roles == 2;

        // Only show status icon for captains, not for members
        if (!isCaptain) {
          return const SizedBox.shrink();
        }

        final status = miqaat.adminApproval.toLowerCase();

        String statusText = 'Pending';
        Color backgroundColor = const Color(0xFFFFF3E0);
        Color textColor = const Color(0xFFE65100);

        if (status == 'approved') {
          statusText = 'Approved';
          backgroundColor = Colors.green;
          textColor = Colors.white;
        } else if (status == 'rejected') {
          statusText = 'Rejected';
          backgroundColor = Colors.red;
          textColor = Colors.white;
        } else {
          statusText = 'Pending';
          backgroundColor = const Color(0xFFFFF3E0);
          textColor = const Color(0xFFE65100);
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 9,
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMiqaatActionDialog(Miqaat miqaat) async {
    // Redirect to new day-wise dialog
    _showDayWiseEnrollmentDialog(miqaat);
  }


  /// Check if a day has already passed (before today - current day is allowed)
  bool _isDayPassed(DateTime dayDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dayDate.year, dayDate.month, dayDate.day);
    return day.isBefore(today);
  }

  Future<void> _showDayWiseEnrollmentDialog(Miqaat miqaat) async {
    final userData = await _localStorage.getUserData();
    if (userData == null || userData.id == 0) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final enrollmentDays = await _miqaatService.getMemberEnrollmentDays(
        miqaatId: miqaat.id,
        memberId: userData.id,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      _showDayWiseDialog(miqaat, enrollmentDays, userData.id);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load enrollment days: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDayWiseDialog(Miqaat miqaat, List<MemberEnrollmentDay> enrollmentDays, int memberId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    miqaat.miqaatName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateRange(miqaat.fromDate, miqaat.tillDate, miqaat.miqaatDays),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const Divider(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Enroll/Reject for each day. Past dates or Captain finalized days are locked.',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: enrollmentDays.isEmpty
                      ? Center(
                          child: Text(
                            'No enrollment data found',
                            style: GoogleFonts.poppins(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: enrollmentDays.length,
                          itemBuilder: (context, index) {
                            final day = enrollmentDays[index];
                            final dayDate = miqaat.fromDate.add(Duration(days: day.day - 1));
                            final isPassed = _isDayPassed(dayDate);
                            final isCaptainFinalized = day.finalStatus != null &&
                                day.finalStatus!.isNotEmpty &&
                                (day.finalStatus == 'Approved' || day.finalStatus == 'Rejected');
                            final isLocked = isPassed || isCaptainFinalized;

                            final isEnrolled = day.status == 'Approved';
                            final isRejected = day.status == 'Rejected';

                            Color cardColor;
                            if (isCaptainFinalized) {
                              cardColor = day.finalStatus == 'Approved'
                                  ? Colors.green.withOpacity(0.08)
                                  : Colors.red.withOpacity(0.08);
                            } else if (isEnrolled) {
                              cardColor = Colors.green.withOpacity(0.06);
                            } else if (isRejected) {
                              cardColor = Colors.red.withOpacity(0.06);
                            } else {
                              cardColor = Colors.orange.withOpacity(0.06);
                            }

                            Color borderColor;
                            if (isCaptainFinalized) {
                              borderColor = day.finalStatus == 'Approved'
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3);
                            } else if (isEnrolled) {
                              borderColor = Colors.green.withOpacity(0.2);
                            } else if (isRejected) {
                              borderColor = Colors.red.withOpacity(0.2);
                            } else {
                              borderColor = Colors.orange.withOpacity(0.2);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Day header row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.primaryGradient,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Day ${day.day}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        day.miqaatDate,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isPassed)
                                        _buildDayBadge('Passed', Colors.grey[600]!),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Status row
                                  Row(
                                    children: [
                                      _buildStatusPill(
                                        'You: ${isEnrolled ? 'Enrolled' : isRejected ? 'Rejected' : 'Pending'}',
                                        isEnrolled ? Colors.green : isRejected ? Colors.red : Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      if (isCaptainFinalized)
                                        _buildStatusPill(
                                          'Captain: ${day.finalStatus}',
                                          day.finalStatus == 'Approved' ? Colors.green : Colors.red,
                                        )
                                      else if (isEnrolled)
                                        _buildStatusPill(
                                          'Captain: Pending',
                                          Colors.grey,
                                        ),
                                    ],
                                  ),
                                  // Admin status row for International / multi-jamaat Local miqaats
                                  if ((miqaat.isInternational || miqaat.isMultiJamaatLocal) && isCaptainFinalized && day.finalStatus == 'Approved') ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _buildStatusPill(
                                          'Admin: ${day.adminStatus ?? 'Pending'}',
                                          day.adminStatus == 'Approved'
                                              ? Colors.green
                                              : day.adminStatus == 'Rejected'
                                                  ? Colors.red
                                                  : const Color(0xFFB8860B),
                                        ),
                                      ],
                                    ),
                                  ],
                                  // Action buttons (only if not locked)
                                  if (!isLocked) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        if (!isEnrolled)
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                await _updateDayStatus(
                                                  miqaat, memberId, day.day, 'Approved',
                                                  dialogContext, setDialogState, enrollmentDays, index,
                                                );
                                              },
                                              icon: const Icon(Icons.check_circle_outline, size: 16),
                                              label: const Text('Enroll', style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                        if (!isEnrolled && !isRejected) const SizedBox(width: 8),
                                        if (!isRejected)
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                await _updateDayStatus(
                                                  miqaat, memberId, day.day, 'Rejected',
                                                  dialogContext, setDialogState, enrollmentDays, index,
                                                );
                                              },
                                              icon: const Icon(Icons.cancel_outlined, size: 16),
                                              label: const Text('Reject', style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  // Locked message
                                  if (isPassed && !isCaptainFinalized) ...[
                                    const SizedBox(height: 6),
                                    const Row(
                                      children: [
                                        Icon(Icons.lock_outline, size: 12, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          'This day has passed',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (isCaptainFinalized) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          day.finalStatus == 'Approved'
                                              ? Icons.verified
                                              : Icons.block,
                                          size: 12,
                                          color: day.finalStatus == 'Approved'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Captain has ${day.finalStatus?.toLowerCase()} this day',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: day.finalStatus == 'Approved'
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDayBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _updateDayStatus(
    Miqaat miqaat,
    int memberId,
    int dayNumber,
    String status,
    BuildContext dialogContext,
    void Function(void Function()) setDialogState,
    List<MemberEnrollmentDay> enrollmentDays,
    int index,
  ) async {
    if (miqaat.isEnrollmentStopped) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enrollment for this have been stopped.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      await _miqaatService.updateMemberMiqaatStatus(
        memberId: memberId,
        miqaatId: miqaat.id,
        status: status,
        days: [dayNumber],
      );

      // Update local state for immediate UI feedback
      setDialogState(() {
        enrollmentDays[index] = MemberEnrollmentDay(
          day: dayNumber,
          status: status,
          finalStatus: enrollmentDays[index].finalStatus,
          adminStatus: enrollmentDays[index].adminStatus,
          miqaatDate: enrollmentDays[index].miqaatDate,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'Approved'
                  ? 'Day $dayNumber enrolled successfully'
                  : 'Day $dayNumber rejected',
            ),
            backgroundColor: status == 'Approved' ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Reload miqaats in background
      _loadMemberMiqaats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
