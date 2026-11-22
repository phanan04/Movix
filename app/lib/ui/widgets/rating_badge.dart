import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RatingBadge extends StatelessWidget {
  final String rating;
  final bool isRed;

  const RatingBadge({
    super.key,
    required this.rating,
    this.isRed = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isRed ? AppColors.primary : Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
        border: isRed ? null : Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Text(
        rating,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
