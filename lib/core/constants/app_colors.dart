import 'package:flutter/material.dart';

class AppColors {
  // ─────────────────────────────────────────────
  //  CORE PALETTE — Maroon / Premium Brown
  // ─────────────────────────────────────────────

  /// Deep maroon — App bars, headers, primary actions
  static const Color primary = Color(0xFF461D17);

  /// Rich dark maroon — Status bar, nav bar backgrounds
  static const Color primaryDark = Color(0xFF3A1410);

  /// Warm maroon — Buttons, active states, highlights
  static const Color primaryLight = Color(0xFF6B2F26);

  /// Lighter maroon — FABs, chips, selected indicators
  static const Color primaryBright = Color(0xFF8B4538);

  /// Soft warm cream — Backgrounds behind cards, tinted surfaces
  static const Color accent = Color(0xFFFFF7EF);

  /// Warm cream — Miqaat cards, warm-toned surfaces
  static const Color accentWarm = Color(0xFFFFFBF0);

  /// Luxury gold — Premium badges, VIP sections
  static const Color accentGold = Color(0xFFD4A574);

  // ─────────────────────────────────────────────
  //  SURFACE & BACKGROUND
  // ─────────────────────────────────────────────

  /// Page background — clean neutral with warm tint
  static const Color background = Color(0xFFF8F5F2);

  /// Card & sheet surfaces — pure white
  static const Color surface = Color(0xFFFFFFFF);

  /// Elevated surface (dialogs, bottom sheets)
  static const Color surfaceElevated = Color(0xFFFFFAF7);

  // ─────────────────────────────────────────────
  //  TEXT
  // ─────────────────────────────────────────────

  /// Primary text — deep charcoal
  static const Color textPrimary = Color(0xFF1A1A2E);

  /// Secondary text — muted warm grey
  static const Color textSecondary = Color(0xFF6B7280);

  /// Hint / disabled text
  static const Color textHint = Color(0xFFA1978E);

  /// Text on dark surfaces (headers, app bars)
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Subtle label on accent backgrounds
  static const Color textOnAccent = Color(0xFF461D17);

  // ─────────────────────────────────────────────
  //  STATUS & SEMANTIC COLORS
  // ─────────────────────────────────────────────

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error   = Color(0xFFC62828);
  static const Color info    = Color(0xFF01579B);

  // ─────────────────────────────────────────────
  //  INTERNATIONAL MIQAAT — Premium Gold (refined)
  // ─────────────────────────────────────────────

  static const Color internationalGold        = Color(0xFFFFCA28);
  static const Color internationalGoldDark    = Color(0xFF9A7200);
  static const Color internationalGoldLight   = Color(0xFFFFF8E1);
  static const Color internationalGoldAccent  = Color(0xFFFFB300);

  // ─────────────────────────────────────────────
  //  DIVIDER / BORDER
  // ─────────────────────────────────────────────

  static const Color divider = Color(0xFFE8D8D6);
  static const Color border  = Color(0xFFCFB2BA);

  // ─────────────────────────────────────────────
  //  GRADIENTS
  // ─────────────────────────────────────────────

  /// Header / AppBar gradient — deep maroon
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3A1410), Color(0xFF461D17), Color(0xFF6B2F26)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hero / splash screen — dramatic dark maroon
  static const Gradient heroGradient = LinearGradient(
    colors: [Color(0xFF2A0E0A), Color(0xFF3A1410), Color(0xFF461D17)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Card highlight — warm maroon shimmer
  static const Gradient cardGradient = LinearGradient(
    colors: [Color(0xFF6B2F26), Color(0xFF8B4538)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// International Miqaat — warm gold gradient
  static const Gradient internationalGradient = LinearGradient(
    colors: [Color(0xFFFFCA28), Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Premium gold-maroon — for VIP / featured banners
  static const Gradient premiumGradient = LinearGradient(
    colors: [Color(0xFF461D17), Color(0xFF9A7200)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─────────────────────────────────────────────
  //  SHADOWS (use with BoxDecoration)
  // ─────────────────────────────────────────────

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF461D17).withOpacity(0.10),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get headerShadow => [
    BoxShadow(
      color: const Color(0xFF3A1410).withOpacity(0.30),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}