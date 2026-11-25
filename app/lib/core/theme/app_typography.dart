import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Hệ thống Typography chuẩn hóa toàn diện trên font chữ Be Vietnam Pro (cached static tokens)
class AppTypography {
  // Hero & Section Headings
  static final TextStyle heroTitle = GoogleFonts.beVietnamPro(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static final TextStyle displayLarge = GoogleFonts.beVietnamPro(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static final TextStyle titleLarge = GoogleFonts.beVietnamPro(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static final TextStyle sectionTitle = GoogleFonts.beVietnamPro(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static final TextStyle titleMedium = GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static final TextStyle titleSmall = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body & Descriptions
  static final TextStyle bodyLarge = GoogleFonts.beVietnamPro(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static final TextStyle bodyMedium = GoogleFonts.beVietnamPro(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static final TextStyle bodySmall = GoogleFonts.beVietnamPro(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Buttons, Badges & Labels (cỡ chữ tối thiểu >= 10.5px để đảm bảo dễ đọc)
  static final TextStyle buttonLarge = GoogleFonts.beVietnamPro(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static final TextStyle buttonMedium = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final TextStyle labelMedium = GoogleFonts.beVietnamPro(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static final TextStyle labelSmall = GoogleFonts.beVietnamPro(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static final TextStyle badge = GoogleFonts.beVietnamPro(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );
}
