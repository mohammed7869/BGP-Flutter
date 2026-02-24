
import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/attendancemiqaatScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/createMiqaatScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/membersListScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/pointsScreen.dart';
import 'package:burhaniguardsapp/ui/widgets/adminAppBar.dart';
import 'package:burhaniguardsapp/ui/widgets/adminAppDrawer.dart';
import 'package:burhaniguardsapp/ui/widgets/adminBottomNavigationBar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final MiqaatService _miqaatService = MiqaatService();
  final LocalStorageService _localStorage = LocalStorageService();
  List<Miqaat> _memberMiqaats = [];
  bool _isLoadingMiqaats = false;

  @override
  void initState() {
    super.initState();
    _loadMemberMiqaats();
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
          miqaats = miqaats
              .where((m) => m.isInternational || (m.jamaat).toLowerCase() == jamaatLower)
              .toList();
        }

        setState(() {
          _memberMiqaats = miqaats;
          _isLoadingMiqaats = false;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load miqaats: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      key: scaffoldKey,
      drawer: const AdminAppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            buildAppBar(context, scaffoldKey),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildShortcuts(),
                    const SizedBox(height: 24),
                    _buildMiqaatSection(),
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
    Future<void> onShortCutTap(int route) async {
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
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shortcuts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3, // number of columns
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 4,
            childAspectRatio: 0.7,
            children: [
              _buildShortcutItem(Icons.supervised_user_circle_sharp, 'Members',
                  () => onShortCutTap(1)),
              _buildShortcutItem(Icons.calendar_today_outlined, 'Miqaats',
                  () => onShortCutTap(2)),
              _buildShortcutItem(Icons.bar_chart_outlined, 'Points',
                  () => onShortCutTap(3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
        onTap: () => onTap(),
        child: Column(
          children: [
            Container(
              // width: 67,
              // height: 66,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4A1C1C),
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF461D17),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ));
  }

  Widget _buildMiqaatSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Miqaat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              // TextButton(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (context) => const MiqaatScreen()),
              //     );
              //   },
              //   child: const Text(
              //     'See All +',
              //     style: TextStyle(
              //       fontSize: 14,
              //       color: Color(0xFF4A1C1C),
              //       fontWeight: FontWeight.w600,
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingMiqaats)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_memberMiqaats.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'No pending miqaats found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            )
          else
            ..._memberMiqaats.map((miqaat) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMiqaatCard(
                    miqaat: miqaat,
                    title: miqaat.miqaatName,
                    dateRange:
                        'FROM ${_formatDate(miqaat.fromDate)} - ${_formatDate(miqaat.tillDate)} (${miqaat.durationLabel})',
                    location: miqaat.isInternational
                        ? 'International Miqaat'
                        : '${miqaat.jamaat}, ${miqaat.jamiyat}',
                  ),
                )),
        ],
      ),
    );
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
    return Container(
      decoration: BoxDecoration(
        color: _isMiqaatCompleted(miqaat.tillDate)
            ? const Color(0xFFE8F5E9)
            : miqaat.isInternational
                ? const Color(0xFFFFF8E1) // Golden background for international
                : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: miqaat.isInternational
            ? Border.all(color: const Color(0xFFFFD54F), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: miqaat.isInternational
                ? const Color(0xFFFFD54F).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: miqaat.isInternational
                              ? const Color(0xFFFFF3E0)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dateRange,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    if (miqaat.isInternational) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
                          ),
                          borderRadius: BorderRadius.circular(4),
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
                    const Spacer(),
                    _buildStatusIcon(miqaat),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: miqaat.isInternational
                  ? const Color(0xFFB8860B) // Dark golden for international
                  : const Color(0xFF4A1C1C),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
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
                        child: Text(
                          buttonText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
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
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A1C1C)),
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
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    miqaat.miqaatName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A1C1C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(miqaat.fromDate)} - ${_formatDate(miqaat.tillDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const Divider(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Color(0xFFE65100)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Enroll/Reject for each day. Past dates or Captain finalized days are locked.',
                            style: TextStyle(fontSize: 10, color: Color(0xFFE65100)),
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
                      ? const Center(
                          child: Text(
                            'No enrollment data found',
                            style: TextStyle(color: Color(0xFF666666)),
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
                                borderRadius: BorderRadius.circular(14),
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
                                          color: const Color(0xFF4A1C1C),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Day ${day.day}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        day.miqaatDate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
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
                                                  borderRadius: BorderRadius.circular(8),
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
                                                  borderRadius: BorderRadius.circular(8),
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
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Color(0xFF4A1C1C)),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

