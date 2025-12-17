import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/core/services/miqaat_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/attendancemiqaatScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/createMiqaatScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/membersListScreen.dart';
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
              .where((m) => (m.jamaat).toLowerCase() == jamaatLower)
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
          MaterialPageRoute(
              builder: (context) => const AttendanceMiqaatScreen()),
        );
      } else if (route == 4) {
        // Check if user is Captain before allowing access to Create Miqaat
        final userData = await _localStorage.getUserData();
        final isCaptain = userData?.roles == 2;

        if (!isCaptain) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Only Captain can create Miqaat'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateMiqaatScreen()),
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
            crossAxisCount: 4, // number of columns
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 4,
            childAspectRatio: 0.7,
            children: [
              _buildShortcutItem(Icons.supervised_user_circle_sharp, 'Members',
                  () => onShortCutTap(1)),
              // _buildShortcutItem(
              //     Icons.event_note_outlined, 'Lawazam', onShortCutTap),
              _buildShortcutItem(Icons.calendar_today_outlined, 'Miqaats',
                  () => onShortCutTap(2)),
              _buildShortcutItem(Icons.bar_chart_outlined, 'Attendance',
                  () => onShortCutTap(3)),
              // _buildShortcutItem(
              //     Icons.history, 'Attendance History', onShortCutTap),
              _buildShortcutItem(Icons.add_circle_outline, 'Create Miqaat',
                  () => onShortCutTap(4)),
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
              maxLines: 2,
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
                        'FROM ${_formatDate(miqaat.fromDate)} - ${_formatDate(miqaat.tillDate)}',
                    location: '${miqaat.jamaat}, ${miqaat.jamiyat}',
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

  Widget _buildMiqaatCard({
    required Miqaat miqaat,
    required String title,
    required String dateRange,
    required String location,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
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
            decoration: const BoxDecoration(
              color: Color(0xFF4A1C1C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: InkWell(
                child: FutureBuilder(
                    future: _localStorage.getUserData(),
                    builder: (context, snapshot) {
                      final isCaptain = snapshot.data?.roles == 2;
                      final memberStatus =
                          miqaat.memberStatus?.toLowerCase() ?? '';
                      final finalStatus =
                          miqaat.finalStatus?.toLowerCase() ?? '';

                      String buttonText = 'View Details';
                      bool enableTap = true;

                      if (!isCaptain) {
                        if (finalStatus == 'approved') {
                          buttonText = 'Approved by Captain';
                          enableTap = false;
                        } else if (finalStatus == 'rejected') {
                          buttonText = 'Rejected by Captain';
                          enableTap = false;
                        } else if (memberStatus == 'approved') {
                          buttonText = 'Enrolled - Awaiting Captain Approval';
                          enableTap = false;
                        } else if (memberStatus == 'rejected') {
                          buttonText = 'Rejected by You';
                          enableTap = false;
                        }
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
                                  _showMiqaatActionDialog(miqaat);
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
    final userData = await _localStorage.getUserData();
    final isCaptain = userData?.roles == 2;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(miqaat.miqaatName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location: ${miqaat.jamaat}, ${miqaat.jamiyat}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${_formatDate(miqaat.fromDate)} - ${_formatDate(miqaat.tillDate)}',
                style: const TextStyle(fontSize: 14),
              ),
              if (miqaat.aboutMiqaat != null &&
                  miqaat.aboutMiqaat!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'About: ${miqaat.aboutMiqaat}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              if (!isCaptain) ...[
                const SizedBox(height: 16),
                const Text(
                  'Would you like to Enroll or Reject this miqaat?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (!isCaptain) ...[
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _updateMiqaatStatus(miqaat, 'Rejected');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Reject'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _updateMiqaatStatus(miqaat, 'Approved');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enroll'),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _updateMiqaatStatus(Miqaat miqaat, String status) async {
    try {
      final userData = await _localStorage.getUserData();
      if (userData == null || userData.id == 0) {
        throw Exception('User not found');
      }

      await _miqaatService.updateMemberMiqaatStatus(
        memberId: userData.id,
        miqaatId: miqaat.id,
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Miqaat $status successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload miqaats to reflect the change
      await _loadMemberMiqaats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
