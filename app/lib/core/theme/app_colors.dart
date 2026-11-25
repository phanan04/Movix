import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Netflix / Movix Signature Red)
  static const Color primary = Color(0xFFE50914); // Iconic Brand Red
  static const Color primaryDark = Color(0xFFC10712); // Hover / Pressed / Dark Red
  static const Color primaryLight = Color(0xFFFF333A);
  static const Color primaryMuted = Color(0x26E50914); // 15% opacity red for badge/chip bg
  static const Color primaryBorder = Color(0x66E50914); // 40% opacity red for borders

  // Backgrounds & Surfaces (Netflix Deep Cinematic Dark #0F1014)
  static const Color background = Color(0xFF0F1014); // OLED Deep Dark
  static const Color surface = Color(0xFF16181F);    // Dark card surface
  static const Color surfaceLight = Color(0xFF1E212A);// Hover / Highlighted card
  static const Color surfaceDarker = Color(0xFF0B0C0E);// Pitch dark
  static const Color surfaceInput = Color(0xFF1B1E28); // Text field background

  // Borders & Dividers
  static const Color border = Color(0xFF222530);
  static const Color borderLight = Color(0xFF2E3240);
  static const Color borderSubtle = Color(0x2EFFFFFF); // Subtle translucent divider

  // Unified Typography Colors (White & Neutral System)
  static const Color textPrimary = Color(0xFFFFFFFF);   // Pure 100% white for titles, active buttons
  static const Color textSecondary = Color(0xFFC4C7D4); // Soft silver white for synopsis, descriptions, info
  static const Color textMuted = Color(0xFF7E8494);     // Refined cool gray for labels, timestamps, inactive nav

  // Accent & Status
  static const Color star = Color(0xFFFFB800);
  static const Color success = Color(0xFF12D18E);
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
