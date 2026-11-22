import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Hệ thống Typography đồng nhất toàn diện trên font chữ Be Vietnam Pro
class AppTypography {
  // Heading & Display
  static TextStyle get displayLarge => GoogleFonts.beVietnamPro(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get titleLarge => GoogleFonts.beVietnamPro(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.25,
      );

  static TextStyle get titleMedium => GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get titleSmall => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // Body & Descriptions
  static TextStyle get bodyLarge => GoogleFonts.beVietnamPro(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle get bodyMedium => GoogleFonts.beVietnamPro(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get bodySmall => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // Buttons, Badges & Labels
  static TextStyle get buttonLarge => GoogleFonts.beVietnamPro(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get buttonMedium => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get labelSmall => GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      );

  static TextStyle get badge => GoogleFonts.beVietnamPro(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );
}
