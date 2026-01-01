import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/auth_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:burhaniguardsapp/ui/widgets/password_change_dialog.dart';
import 'package:burhaniguardsapp/ui/widgets/baawan_erp_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  late AnimationController _pulseController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    // Pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Color animation controller
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Scale animation (pulse between 1.0 and 1.1)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Color animation (transition between primary and blue)
    _colorAnimation = ColorTween(
      begin: AppColors.primary,
      end: Colors.blue,
    ).animate(
      CurvedAnimation(
        parent: _colorController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _colorController.dispose();
    _itsNoController.dispose();
    _passwordController.dispose();
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
            // Login successful - user data is already stored in local storage
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Login successful!"),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to dashboard after login
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
                          // Logo at the top
                          _buildLogo(),
                        ],
                      ),
                    ),
                  ),
                  // Central card with form - aligned at bottom
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24.0),
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.50),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Image.asset(
                              'assets/images/burhaniguards_logo.png',
                              height: 113,
                            ),
                            const SizedBox(height: 32),
                            // ITS No. Field
                            TextFormField(
                                    controller: _itsNoController,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: "ITS No.",
                                      labelStyle: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.badge,
                                        color: AppColors.primary,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    maxLength: 8,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "ITS No. is required";
                                      }
                                      if (!RegExp(r'^\d+$').hasMatch(value)) {
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
                                // Password Field
                                TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: "Password",
                                      labelStyle: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock,
                                        color: AppColors.primary,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: AppColors.primary,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Password is required";
                                      }
                                      return null;
                                    },
                                ),
                                const SizedBox(height: 24),
                                // Login Button
                                _buildButtons(context, _submit),
                              ],
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),
                  // Footer
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              );
            },
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
      // child: Image.asset(
      //   'assets/images/burhaniguards_logo.png',
      //   height: 113,
      // ),
    );
  }

  Widget _buildButtons(BuildContext context, onSubmit) {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            'Login',
            onPressed: () {
              onSubmit();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, {required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        elevation: 2,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Powered By',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 8,
                offset: const Offset(5, 1),
              ),
            ],
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
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _colorController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Text(
                  'Baawan.com',
                  style: TextStyle(
                    fontSize: 16,
                    color: _colorAnimation.value,
                    decoration: TextDecoration.underline,
                    decorationColor: _colorAnimation.value,
                    decorationThickness: 1.5,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.9),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
                  const SnackBar(
                    content: Text(
                        "Password changed successfully! Please login with your new password."),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
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
