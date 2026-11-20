import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (from Movix Figma design)
  static const Color primary = Color(0xFFE21221); // Movix Red / Netflix Red
  static const Color primaryLight = Color(0xFFFF3B30);
  static const Color primaryDark = Color(0xFFB70E1A);

  // Backgrounds & Surfaces (Pure Dark theme)
  static const Color background = Color(0xFF181A20); // Dark background
  static const Color surface = Color(0xFF1F222A);    // Card / Container background
  static const Color surfaceLight = Color(0xFF262A34);// Hover / Highlighted card
  static const Color surfaceDarker = Color(0xFF121316);// Extra dark background

  // Borders & Dividers
  static const Color border = Color(0xFF2F3342);
  static const Color borderLight = Color(0xFF35383F);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF757575);

  // Accent & Status
  static const Color star = Color(0xFFFFC107);
  static const Color success = Color(0xFF12D18E);
  static const Color info = Color(0xFF246BFD);
  static const Color warning = Color(0xFFFACC15);

  // Overlay gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x99181A20),
      Color(0xFF181A20),
    ],
    stops: [0.3, 0.75, 1.0],
  );

  static const LinearGradient cardOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0xCC000000),
    ],
    stops: [0.5, 1.0],
  );
}
