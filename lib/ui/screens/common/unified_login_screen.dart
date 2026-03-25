import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/auth_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:burhaniguardsapp/ui/screens/common/forgot_password_screen.dart';
import 'package:burhaniguardsapp/ui/screens/common/privacyPolicyScreen.dart';
import 'package:burhaniguardsapp/ui/widgets/password_change_dialog.dart';
import 'package:burhaniguardsapp/ui/widgets/baawan_erp_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({Key? key}) : super(key: key);

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itsNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  // ── Animation controllers ──
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _logoController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Logo entrance
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _logoScaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    // Card fade
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Card slide up
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Stagger: logo → card
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _itsNoController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final itsNo = _itsNoController.text.trim();
        final password = _passwordController.text;

        final response = await _authService.login(itsNo, password);

        if (response != null && mounted) {
          // Check if password change is required (new_password_hash is NULL)
          if (response.requiresPasswordChange) {
            // Show password change dialog
            _showPasswordChangeDialog(response.fullName, itsNo);
          } else {
            // Login successful - navigate directly to dashboard
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Login successful!"),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
            _navigateToDashboard();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/welcome2.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // Gradient overlay on top of background image
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryDark.withOpacity(0.25),
                AppColors.primary.withOpacity(0.25),
                AppColors.primaryLight.withOpacity(0.25),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Animated logo at top
                            ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: _buildLogo(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Animated glassmorphic card ──
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Center(
                          child: Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            padding: const EdgeInsets.all(28.0),
                            decoration: BoxDecoration(
                              // Glassmorphism
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.30),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Logo inside card
                                      Image.asset(
                                        'assets/images/burhaniguards_logo.png',
                                        height: 100,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Welcome Back',
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Sign in to continue',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      // ── ITS No. Field ──
                                      _buildInputField(
                                        controller: _itsNoController,
                                        label: 'ITS No.',
                                        icon: Icons.badge_outlined,
                                        keyboardType: TextInputType.number,
                                        maxLength: 8,
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty) {
                                            return "ITS No. is required";
                                          }
                                          if (!RegExp(r'^\d+$')
                                              .hasMatch(value)) {
                                            return "Only numerical values are allowed";
                                          }
                                          if (value.length < 8) {
                                            return "ITS No. must be exactly 8 digits";
                                          }
                                          if (value.length > 8) {
                                            return "ITS No. must be maximum 8 characters";
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      // ── Password Field ──
                                      _buildInputField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        obscureText: !_isPasswordVisible,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_rounded
                                                : Icons
                                                    .visibility_off_rounded,
                                            color: Colors.white70,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.isEmpty) {
                                            return "Password is required";
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      // Forgot Password Link
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const ForgotPasswordScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Forgot Password?',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // ── Login Button ──
                                      _buildLoginButton(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Footer
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildFooter(),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable input field ──
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        counterStyle: const TextStyle(color: Colors.white60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.20), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.red.shade300, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        errorStyle: TextStyle(color: Colors.red.shade200),
      ),
      validator: validator,
    );
  }

  // ── Gradient login button ──
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _isLoading
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.5),
                    AppColors.primaryLight.withOpacity(0.5),
                  ],
                )
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Powered By',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white60,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext dialogContext) {
                return const BaawanErpDialog();
              },
            );
          },
          child: Text(
            'Baawan.com',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white70,
              decorationThickness: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'For more info, please read ',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white54,
                fontWeight: FontWeight.w400,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
              child: Text(
                'Privacy Policy',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white70,
                  decorationThickness: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPasswordChangeDialog(String memberName, String itsNumber) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must change password
      builder: (BuildContext dialogContext) {
        return PasswordChangeDialog(
          captainName: memberName,
          onPasswordChanged:
              (String newPassword, String confirmPassword) async {
            try {
              final success = await _authService.changePassword(
                itsNumber,
                newPassword,
                confirmPassword,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                        "Password changed successfully! Please login with your new password."),
                    backgroundColor: Colors.green.shade600,
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );

                // Clear password field for re-login
                _passwordController.clear();
                return true;
              }
              return false;
            } catch (e) {
              // Error will be shown in dialog, rethrow to let dialog handle it
              rethrow;
            }
          },
        );
      },
    );
  }

  void _showBaawanErpDialogAndNavigate() {
    if (mounted) {
      bool websiteVisited = false;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return BaawanErpDialog(
            onWebsiteVisited: () {
              websiteVisited = true;
            },
          );
        },
      ).then((_) async {
        // Navigate to dashboard after dialog is dismissed
        // Add a delay to allow browser to open if website was visited
        if (mounted) {
          if (websiteVisited) {
            // Give browser time to open before navigating
            await Future.delayed(const Duration(milliseconds: 1000));
          } else {
            // Small delay even when just closing to ensure smooth transition
            await Future.delayed(const Duration(milliseconds: 300));
          }
          if (mounted) {
            _navigateToDashboard();
          }
        }
      });
    }
  }

  void _navigateToDashboard() {
    // TODO: Navigate to appropriate dashboard based on role
    // For now, navigate to admin dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
    );
  }
}
