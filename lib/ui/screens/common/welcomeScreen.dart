import 'package:burhaniguardsapp/core/constants/app_colors.dart';
import 'package:burhaniguardsapp/ui/screens/admin/admin_login.dart';
import 'package:burhaniguardsapp/ui/screens/user/memberLoginScreen.dart';
import 'package:burhaniguardsapp/ui/widgets/shaped_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                // Buttons Section
                _buildButtons(context),
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
          'Welcome',
          style: GoogleFonts.poppins(
              fontSize: 55,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Hello there, how would you like to\nlogin as?',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 18, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            'Member',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MemberLoginScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildButton(
            'Captain',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminLoginScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, {required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        elevation: 2,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: const [
        Text(
          'Powered By',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.primary,
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue, // optional
            decorationThickness: 2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Clear Concept Solutions',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            // fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue, // optional
            decorationThickness: 2,
          ),
        ),
      ],
    );
  }
}
