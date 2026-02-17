import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF461D17); // Example purple
  static const Color accent = Color(0xFFFFF7EF); // Orange
  static const Color background = Color(0xFFF5F5F5); // Light gray
  static const Color textPrimary = Color(0xFF212121); // Dark text
  static const Color textSecondary = Color(0xFF757575); // Grey text

  // International Miqaat golden colors
  static const Color internationalGold = Color(0xFFFFD54F);
  static const Color internationalGoldDark = Color(0xFFB8860B);
  static const Color internationalGoldLight = Color(0xFFFFF8E1);
  static const Color internationalGoldAccent = Color(0xFFFFA726);

  // You can add gradients too
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient internationalGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
