import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Netflix / Movix Brand Red)
  static const Color primary = Color(0xFFE50914); // Netflix Red
  static const Color primaryLight = Color(0xFFFF2430);
  static const Color primaryDark = Color(0xFFB80710);

  // Backgrounds & Surfaces (Netflix Deep Cinematic Dark #0F1014)
  static const Color background = Color(0xFF0F1014); // OLED Deep Dark
  static const Color surface = Color(0xFF16181F);    // Dark card surface
  static const Color surfaceLight = Color(0xFF1E212A);// Hover / Highlighted card
  static const Color surfaceDarker = Color(0xFF0B0C0E);// Pitch dark

  // Borders & Dividers
  static const Color border = Color(0xFF222530);
  static const Color borderLight = Color(0xFF2E3240);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF757575);

  // Accent & Status
  static const Color star = Color(0xFFFFC107);
  static const Color success = Color(0xFF12D18E);
  static const Color info = Color(0xFF246BFD);
  static const Color warning = Color(0xFFFACC15);

  // Overlay gradients (Smooth fade to #0F1014)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x800F1014),
      Color(0xFF0F1014),
    ],
    stops: [0.3, 0.72, 1.0],
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
