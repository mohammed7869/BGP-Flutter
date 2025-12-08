import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF461D17); // Example purple
  static const Color accent = Color(0xFFFFF7EF); // Orange
  static const Color background = Color(0xFFF5F5F5); // Light gray
  static const Color textPrimary = Color(0xFF212121); // Dark text
  static const Color textSecondary = Color(0xFF757575); // Grey text

  // You can add gradients too
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
