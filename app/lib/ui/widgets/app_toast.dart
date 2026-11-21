import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Modern Streaming App Toast / HUD Notification (Netflix & Apple TV Style)
class AppToast {
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    bool isError = false,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F222B).withValues(alpha: 0.95),
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isError ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? (isError ? Icons.info_outline_rounded : Icons.check_circle_rounded),
              color: isError ? AppColors.primary : const Color(0xFF4ADE80),
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
