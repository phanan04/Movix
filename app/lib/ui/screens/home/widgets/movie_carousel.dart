import 'package:flutter/material.dart';
import '../../../../core/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../widgets/movie_card.dart';
import '../../../widgets/tv_focusable.dart';

class MovieCarouselSection extends StatelessWidget {
  final String title;
  final List<MovieItem> movies;
  final VoidCallback? onSeeAll;

  const MovieCarouselSection({
    super.key,
    required this.title,
    required this.movies,
    this.onSeeAll,
  });

  Widget _buildSeeAllCard(BuildContext context) {
    return TVFocusable(
      onPressed: onSeeAll,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 130,
        height: 190,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Xem tất cả →',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) return const SizedBox.shrink();

    final isWide = MediaQuery.of(context).size.width >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.sectionTitle,
              ),
              if (!isWide && onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Carousel List with tuned cacheExtent for buttery 60/120fps scrolling
        SizedBox(
          height: 245,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            cacheExtent: 500, // Pre-render 500px off-screen
            itemCount: movies.length + (isWide && onSeeAll != null ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == movies.length) {
                return _buildSeeAllCard(context);
              }
              return MovieCard(movie: movies[index]);
            },
          ),
        ),
      ],
    );
  }
}
