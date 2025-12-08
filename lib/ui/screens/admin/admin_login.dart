import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/auth_service.dart';
import 'package:burhaniguardsapp/ui/screens/admin/adminDashboard.dart';
import 'package:burhaniguardsapp/ui/widgets/password_change_dialog.dart';
import 'package:burhaniguardsapp/ui/widgets/shaped_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itsNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

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

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen()),
            );
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
      body: ShapedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo and Title Section
                _buildHeader(),
                const Spacer(),

                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ITS No. Field
                      TextFormField(
                        controller: _itsNoController,
                        decoration: const InputDecoration(
                          labelText: "ITS No.",
                          prefixIcon: Icon(Icons.badge),
                          border: UnderlineInputBorder(),
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
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          border: const UnderlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
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
                    ],
                  ),
                ),

                // Buttons Section
                _buildButtons(context, _submit),
                const SizedBox(height: 40),
                // Footer
                _buildFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo with laurel wreath
        Image.asset('assets/images/burhaniguards_logo.png', height: 113),
        const SizedBox(height: 8),

        const SizedBox(height: 40),
        Text(
          'Login as Captain',
          style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
        ),
      ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'want to login as a user?',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.primary,
          ),
        ),
        // SizedBox(height: 4),

        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Click Here',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ))
      ],
    );
  }

  void _showPasswordChangeDialog(String captainName, String itsNumber) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must change password
      builder: (BuildContext dialogContext) {
        return PasswordChangeDialog(
          captainName: captainName,
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
}
