import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:burhaniguardsapp/ui/screens/admin/miqaatAttendanceScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/memberMiqaatHistoryScreen.dart';
import 'package:burhaniguardsapp/ui/screens/common/bohraCalendarScreen.dart';
import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
import 'package:burhaniguardsapp/ui/widgets/adminBottomNavigationBar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceMiqaatScreen extends StatefulWidget {
  final String? initialFilter;

  const AttendanceMiqaatScreen({Key? key, this.initialFilter})
      : super(key: key);

  @override
  State<AttendanceMiqaatScreen> createState() => _AttendanceMiqaatScreenState();
}

class _AttendanceMiqaatScreenState extends State<AttendanceMiqaatScreen>
    with SingleTickerProviderStateMixin {
  bool _isCaptain = false;

  final MiqaatService _miqaatService = MiqaatService();
  final LocalStorageService _localStorage = LocalStorageService();
  List<Miqaat> _miqaats = [];
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _listAnimController;

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadMiqaats();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadMiqaats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _localStorage.getUserData();
      final miqaats = await _miqaatService.getAllMiqaats();
      final isCaptain = user != null && user.roles == 2;

      List<Miqaat> filtered = miqaats;
      if (user != null && user.jamaat != null) {
        final userJamaat = user.jamaat!.toLowerCase();
        filtered = miqaats.where((m) {
          if (m.isInternational) {
            if (m.jamaat.trim().isEmpty) return true;
            return m.jamaat.toLowerCase().split(',').map((e) => e.trim()).contains(userJamaat);
          }
          return m.jamaat.toLowerCase().split(',').map((e) => e.trim()).contains(userJamaat);
        }).toList();
      }

      setState(() {
        _miqaats = filtered;
        _isCaptain = isCaptain;
        _isLoading = false;
      });
      _listAnimController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isCaptain = false;
      });
    }
  }

  void _handleBackNavigation(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
    );
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
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          _handleBackNavigation(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Premium AppBar with Calendar + Logout
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 24),
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
                      onPressed: () => _handleBackNavigation(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Image.asset('assets/images/burhani guards logo.png',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance / Miqaat\'s',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${_miqaats.length} miqaat${_miqaats.length != 1 ? 's' : ''} found',
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
                        : _errorMessage != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        size: 48,
                                        color: Colors.red.withOpacity(0.6),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage!,
                                        style: GoogleFonts.poppins(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        onPressed: _loadMiqaats,
                                        icon: const Icon(Icons.refresh,
                                            size: 18),
                                        label: const Text('Retry'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primary,
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
                            : _miqaats.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons
                                              .event_available_rounded,
                                          size: 56,
                                          color: AppColors.primary
                                              .withOpacity(0.2),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No miqaats found',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color:
                                                AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadMiqaats,
                                    color: AppColors.primary,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      itemCount: _miqaats.length,
                                      itemBuilder: (context, index) {
                                        return TweenAnimationBuilder<
                                            double>(
                                          tween: Tween(
                                              begin: 0.0, end: 1.0),
                                          duration: Duration(
                                              milliseconds:
                                                  400 + (index * 100)),
                                          curve: Curves.easeOutCubic,
                                          builder:
                                              (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset: Offset(
                                                    0, 20 * (1 - value)),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: _buildMiqaatCard(
                                              _miqaats[index], context),
                                        );
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavBarCaptain(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  Widget _buildMiqaatCard(Miqaat miqaat, BuildContext context) {
    final fromDateStr = _formatDate(miqaat.fromDate);
    final tillDateStr = _formatDate(miqaat.tillDate);
    final dateDisplay = fromDateStr == tillDateStr
        ? fromDateStr
        : '$fromDateStr - $tillDateStr';
    final durationDisplay = '${miqaat.durationLabel}';

    String statusText = 'Pending';
    Color statusBg = const Color(0xFFFFF3E0);
    Color statusFg = const Color(0xFFE65100);
    IconData statusIcon = Icons.access_time_rounded;
    if (miqaat.adminApproval.toLowerCase() == 'approved') {
      statusText = 'Approved';
      statusBg = const Color(0xFFE8F5E9);
      statusFg = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_rounded;
    } else if (miqaat.adminApproval.toLowerCase() == 'rejected') {
      statusText = 'Rejected';
      statusBg = const Color(0xFFFFEBEE);
      statusFg = const Color(0xFFC62828);
      statusIcon = Icons.cancel_rounded;
    }

    return GestureDetector(
      onTap: () async {
        final user = await _localStorage.getUserData();
        if (user == null) return;

        if (user.roles == 2 &&
            miqaat.adminApproval.toLowerCase() == 'approved') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MiqaatAttendanceScreen(miqaat: miqaat),
            ),
          );
        } else if (user.roles != 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberMiqaatHistoryScreen(
                memberId: user.id,
                fullName: user.fullName,
                itsId: user.itsId,
                miqaatId: miqaat.id,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: miqaat.isInternational
              ? AppColors.internationalGoldLight
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: miqaat.isInternational
                ? AppColors.internationalGold.withOpacity(0.5)
                : Colors.grey.withOpacity(0.1),
            width: miqaat.isInternational ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: miqaat.isInternational
                  ? AppColors.internationalGold.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
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
                  // Top row: Date + Status badge
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '$dateDisplay • $durationDisplay',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.internationalGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '🌍',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                      if (_isCaptain) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon,
                                  size: 12, color: statusFg),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: statusFg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    miqaat.miqaatName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Location
                  Row(
                    children: [
                      Icon(
                        miqaat.isInternational
                            ? Icons.public
                            : Icons.location_on_outlined,
                        size: 15,
                        color: miqaat.isInternational
                            ? AppColors.internationalGoldDark
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          miqaat.isInternational
                              ? 'International Miqaat'
                              : _isCaptain
                                  ? '${miqaat.jamaat} (${miqaat.jamiyat})'
                                  : miqaat.jamaat,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: miqaat.isInternational
                                ? AppColors.internationalGoldDark
                                : AppColors.textSecondary,
                            fontWeight: miqaat.isInternational
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (!_isCaptain) ...[
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.only(left: 19),
                      child: Text(
                        miqaat.jamiyat,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  if (_isCaptain) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Volunteer Limit: ${miqaat.volunteerLimit}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Bottom arrow indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: miqaat.isInternational
                    ? const LinearGradient(
                        colors: [Color(0xFFB8860B), Color(0xFFDAA520)])
                    : AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isCaptain
                          ? 'View Attendance'
                          : 'View Details',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white70, size: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
