import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/auth_service.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
// import 'package:burhaniguardsapp/ui/screens/admin/attendancemiqaatScreen.dart';
// import 'package:burhaniguardsapp/ui/screens/admin/miqaats_Screen.dart';
import 'package:burhaniguardsapp/ui/screens/common/hierarchyScreen.dart';
import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
// import 'package:burhaniguardsapp/ui/screens/user/enrolledEvents.dart';
import 'package:burhaniguardsapp/ui/screens/user/profileScreen.dart';
import 'package:burhaniguardsapp/ui/screens/survey/survey_form_screen.dart';
import 'package:burhaniguardsapp/ui/widgets/survey_popup.dart';
import 'package:burhaniguardsapp/ui/widgets/password_change_dialog.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminAppDrawer extends StatefulWidget {
  const AdminAppDrawer({Key? key}) : super(key: key);

  @override
  State<AdminAppDrawer> createState() => _AdminAppDrawerState();
}

class _AdminAppDrawerState extends State<AdminAppDrawer> {
  String? _userName;
  String? _userItsId;
  String? _userJamaat;
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final localStorage = LocalStorageService();
    final userData = await localStorage.getUserData();
    setState(() {
      _userName = userData?.fullName ?? 'User';
      _userItsId = userData?.itsId;
      _userJamaat = userData?.jamaat;
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
                                AppColors.primary),
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
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 4,
                  radius: const Radius.circular(10),
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
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
                      _buildMenuItem(
                        context,
                        icon: Icons.account_tree_rounded,
                        title: 'Hierarchy',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HierarchyScreen()),
                          );
                        },
                      ),
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
                        icon: Icons.dry_cleaning,
                        title: 'Uniform',
                        onTap: () async {
                          Navigator.pop(context);
                          final Uri url =
                              Uri.parse('https://forms.gle/SxZUJQ1zp7EfoPiZ6');
                          if (!await launchUrl(url,
                              mode: LaunchMode.externalApplication)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Could not launch Uniform URL')),
                              );
                            }
                          }
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.public,
                        title: 'BGI',
                        onTap: () async {
                          Navigator.pop(context);
                          final Uri url =
                              Uri.parse('https://app.burhaniguards.org/dashboard');
                          if (!await launchUrl(url,
                              mode: LaunchMode.externalApplication)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Could not launch BGI URL')),
                              );
                            }
                          }
                        },
                      ),
                      // --- Khidmat Survey has been stopped (Ashara Mubaraka Poona 1448) ---
                      // Survey menu item hidden from sidebar
                      // if (!['BARAMATI', 'AHMEDNAGAR'].contains(
                      //     (_userJamaat ?? '').toUpperCase().trim()))
                      //   _buildMenuItem(
                      //     context,
                      //     icon: Icons.assignment_rounded,
                      //     title: 'Survey',
                      //     onTap: () async {
                      //       Navigator.pop(context);
                      //       final shown =
                      //           await SurveyPopup.showIfNeeded(context);
                      //       if (!shown && context.mounted) {
                      //         Navigator.push(
                      //           context,
                      //           MaterialPageRoute(
                      //               builder: (_) => const SurveyFormScreen(
                      //                   isPreview: true)),
                      //         );
                      //       }
                      //     },
                      //   ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Buttons (Reset Password & Logout)
            SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // Reset Password Button
                    ListTile(
                      leading: Icon(
                        Icons.lock_reset,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      minLeadingWidth: 0,
                      horizontalTitleGap: 12,
                      title: Text(
                        'Reset Password',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        _handleResetPassword(context);
                      },
                    ),
                    const Divider(height: 1),
                    // Logout Button
                    ListTile(
                      leading: const Icon(
                        Icons.exit_to_app,
                        color: Colors.red,
                        size: 22,
                      ),
                      minLeadingWidth: 0,
                      horizontalTitleGap: 12,
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
                    const SizedBox(height: 16),
                  ],
                ),
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
        color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primaryDark,
          size: 22,
        ),
        minLeadingWidth: 0,
        horizontalTitleGap: 12,
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Future<void> _handleResetPassword(BuildContext context) async {
    if (_userItsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to reset password. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show password change dialog (Drawer stays open)
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return PasswordChangeDialog(
          captainName: _userName ?? 'User',
          title: 'Reset Password',
          subtitle: 'Enter your new password to reset',
          isDismissible: true,
          onPasswordChanged: (String newPassword, String confirmPassword) async {
            try {
              final success = await _authService.changePassword(
                _userItsId!,
                newPassword,
                confirmPassword,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset successfully!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
                return true;
              }
              return false;
            } catch (e) {
              rethrow;
            }
          },
        );
      },
    );

    // Close the drawer after dialog is closed
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}
