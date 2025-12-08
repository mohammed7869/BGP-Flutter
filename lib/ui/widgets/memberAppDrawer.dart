import 'package:burhaniguardsapp/ui/screens/admin/attendancemiqaatScreen.dart';
import 'package:burhaniguardsapp/ui/screens/user/enrolledEvents.dart';
import 'package:burhaniguardsapp/ui/screens/user/memberDashboard.dart';
import 'package:burhaniguardsapp/ui/screens/user/miqaatListScreen.dart';
import 'package:burhaniguardsapp/ui/screens/user/profileScreen.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF4A1C1C), // Matching your app bar color
        child: Column(
          children: [
            // Header Section with Logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(
                color: Color(0xFF4A1C1C),
              ),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/images/burhaniguards_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.security,
                            size: 50,
                            color: Color(0xFF4A1C1C),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Company Name
                  // const Text(
                  //   'Pankaj Mehandiratta Paints',
                  //   style: TextStyle(
                  //     color: Colors.white70,
                  //     fontSize: 12,
                  //     letterSpacing: 0.5,
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    'Burhani Guards',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Subtitle
                  const Text(
                    'Logged in as User',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8F0), // Light cream background
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.only(top: 20),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.home_outlined,
                      title: 'Home',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HomeMiqaatScreen()),
                        );
                        // Navigate to Home
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.grid_view_outlined,
                      title: 'Miqaats',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MiqaatListScreen()),
                        );
                        // Navigate to Miqaats
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.calendar_today_outlined,
                      title: 'Attendance',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AttendanceMiqaatScreen()),
                        );
                        // Navigate to Attendance
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UserProfileScreen()),
                        );
                        // Navigate to Profile
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.event_outlined,
                      title: 'Enrolled Events',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EnrolledMiqaatScreen()),
                        );
                        // Navigate to Enrolled Events
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.bookmark_border,
                      title: 'Saved Events',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EnrolledMiqaatScreen()),
                        );
                        // Navigate to Saved Events
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Logout Button
            Container(
              color: const Color(0xFFFFF8F0),
              padding: const EdgeInsets.all(20),
              child: ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 22,
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF4A1C1C),
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF4A1C1C),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle logout logic here
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
