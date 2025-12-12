import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
// import 'package:burhaniguardsapp/ui/screens/admin/attendancemiqaatScreen.dart';
// import 'package:burhaniguardsapp/ui/screens/admin/miqaats_Screen.dart';
import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
import 'package:burhaniguardsapp/ui/screens/user/enrolledEvents.dart';
import 'package:burhaniguardsapp/ui/screens/user/profileScreen.dart';
import 'package:flutter/material.dart';

class AdminAppDrawer extends StatefulWidget {
  const AdminAppDrawer({Key? key}) : super(key: key);

  @override
  State<AdminAppDrawer> createState() => _AdminAppDrawerState();
}

class _AdminAppDrawerState extends State<AdminAppDrawer> {
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final localStorage = LocalStorageService();
    final userData = await localStorage.getUserData();
    setState(() {
      _userName = userData?.fullName ?? 'User';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header Section with Logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  // Hamburger Logo
                  Image.asset(
                    'assets/images/burhaniguards_logo.png',
                    height: 113,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/burhaniguards_logo.png',
                        height: 113,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // Title
                  const Text(
                    'Burhani Guards',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Subtitle
                  _isLoading
                      ? const SizedBox(
                          height: 13,
                          width: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF461D17)),
                          ),
                        )
                      : Text(
                          'Logged in as $_userName',
                          style: const TextStyle(
                            color: Colors.black87,
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
                  color: Colors.white,
                ),
                child: ListView(
                  padding: const EdgeInsets.only(top: 20),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.home,
                      title: 'Home',
                      isSelected: true,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminDashboardScreen()),
                        );
                      },
                    ),
                    // _buildMenuItem(
                    //   context,
                    //   icon: Icons.calendar_today,
                    //   title: 'Miqaats',
                    //   onTap: () {
                    //     Navigator.pop(context);
                    //     Navigator.pushReplacement(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (_) => const MiqaatScreen()),
                    //     );
                    //   },
                    // ),
                    // _buildMenuItem(
                    //   context,
                    //   icon: Icons.bar_chart,
                    //   title: 'Attendance',
                    //   onTap: () {
                    //     Navigator.pop(context);
                    //     Navigator.pushReplacement(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (_) => const AttendanceMiqaatScreen()),
                    //     );
                    //   },
                    // ),
                    _buildMenuItem(
                      context,
                      icon: Icons.person,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UserProfileScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.event_available,
                      title: 'Enrolled Events',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EnrolledMiqaatScreen()),
                        );
                      },
                    ),
                    // _buildMenuItem(
                    //   context,
                    //   icon: Icons.bookmark,
                    //   title: 'Saved Events',
                    //   onTap: () {
                    //     Navigator.pop(context);
                    //     Navigator.pushReplacement(
                    //       context,
                    //       MaterialPageRoute(
                    //           builder: (_) => const EnrolledMiqaatScreen()),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
            ),

            // Logout Button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: ListTile(
                leading: const Icon(
                  Icons.exit_to_app,
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
                  _handleLogout(context);
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
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFE5D9) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF461D17),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color:
                isSelected ? const Color(0xFF461D17) : const Color(0xFF461D17),
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog first (before closing drawer)
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
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    // Close drawer if it's still open
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Proceed with logout if user confirmed
    if (shouldLogout == true && mounted) {
      try {
        // Clear local storage
        final localStorage = LocalStorageService();
        await localStorage.clearAll();

        // Navigate to login screen and clear navigation stack
        // Use rootNavigator to ensure we can navigate even if drawer context is gone
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        // If navigation fails, try with regular context
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const UnifiedLoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }
}
