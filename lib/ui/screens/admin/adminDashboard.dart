import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/ui/screens/admin/addUserScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/attendancemiqaatScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/createMiqaatScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/enrolledMembersListScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/membersListScreen.dart';
import 'package:burhaniguardsapp/ui/screens/admin/miqaats_Screen.dart';
import 'package:burhaniguardsapp/ui/widgets/adminAppBar.dart';
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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      key: scaffoldKey,
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
          MaterialPageRoute(
              builder: (context) => const AttendanceMiqaatScreen()),
        );
      } else if (route == 4) {
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
              _buildShortcutItem(Icons.add_circle_outline, 'Create\nMiqaats',
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
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MiqaatScreen()),
                  );
                },
                child: const Text(
                  'See All +',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A1C1C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMiqaatCard(
            title: 'Eid E Milood Un Nabi',
            dateRange: 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
            location: 'Mumbai, Santa Cruz',
          ),
          const SizedBox(height: 12),
          _buildMiqaatCard(
            title: 'Eid E Milood Un Nabi',
            dateRange: 'ENROLLED FROM 2ND OCT - 9TH OCT 2023',
            location: 'Mumbai, Santa Cruz',
          ),
        ],
      ),
    );
  }

  Widget _buildMiqaatCard({
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MembersListScreen()),
                  );
                },
                child: Text(
                  'Check Members List',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
