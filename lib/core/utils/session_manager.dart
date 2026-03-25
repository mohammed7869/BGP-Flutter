import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/core/services/auth_service.dart';
import 'package:burhaniguardsapp/core/services/local_storage_service.dart';
import 'package:burhaniguardsapp/ui/screens/common/unified_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utility class to handle session expiry across the app.
/// When a 401 error is detected, it shows a re-login popup with
/// the user's ITS ID pre-filled so they can quickly re-authenticate.
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static bool _isDialogShowing = false;

  /// Check if an error message indicates a session expiry (401 / unauthorized).
  static bool isSessionExpired(dynamic error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('unauthorized') ||
        msg.contains('401') ||
        msg.contains('user not authenticated') ||
        msg.contains('please login again');
  }

  /// Handle session expiry: show a re-login popup with ITS ID pre-filled.
  /// [context] – current BuildContext
  /// [onReLoginSuccess] – callback to retry the failed operation after successful re-login
  static Future<void> handleSessionExpiry(
    BuildContext context, {
    VoidCallback? onReLoginSuccess,
  }) async {
    if (_isDialogShowing) return; // Prevent multiple dialogs
    _isDialogShowing = true;

    final localStorage = LocalStorageService();
    final userData = await localStorage.getUserData();
    final storedItsId = userData?.itsId ?? '';

    if (!context.mounted) {
      _isDialogShowing = false;
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _ReLoginDialog(
          itsId: storedItsId,
          onSuccess: () {
            _isDialogShowing = false;
            Navigator.of(dialogContext).pop();
            onReLoginSuccess?.call();
          },
          onGoToLogin: () {
            _isDialogShowing = false;
            Navigator.of(dialogContext).pop();
            // Navigate to login screen, clearing the navigation stack
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const UnifiedLoginScreen(),
              ),
              (route) => false,
            );
          },
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }
}

class _ReLoginDialog extends StatefulWidget {
  final String itsId;
  final VoidCallback onSuccess;
  final VoidCallback onGoToLogin;

  const _ReLoginDialog({
    required this.itsId,
    required this.onSuccess,
    required this.onGoToLogin,
  });

  @override
  State<_ReLoginDialog> createState() => _ReLoginDialogState();
}

class _ReLoginDialogState extends State<_ReLoginDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _reLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.login(
        widget.itsId,
        _passwordController.text,
      );

      if (response != null && mounted) {
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF6F9FB)],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Session expired icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Session Expired',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your session has expired. Please enter your password to continue.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // ITS ID display (read-only)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ITS No.',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.itsId,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                autofocus: true,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _reLogin(),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _isLoading
                        ? LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.5),
                              AppColors.primaryLight.withOpacity(0.5),
                            ],
                          )
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _reLogin,
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
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Login & Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Go to login screen button
              TextButton(
                onPressed: widget.onGoToLogin,
                child: Text(
                  'Go to Login Screen',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
