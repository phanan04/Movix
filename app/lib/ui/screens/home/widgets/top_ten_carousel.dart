import 'package:flutter/material.dart';
import '../../../../core/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/cached_poster_image.dart';
import '../../../widgets/rating_badge.dart';
import '../../../widgets/tv_focusable.dart';
import '../../movie_detail/movie_detail_screen.dart';

class TopTenCarousel extends StatelessWidget {
  final List<MovieItem> movies;
  final VoidCallback? onSeeAll;

  const TopTenCarousel({
    super.key,
    required this.movies,
    this.onSeeAll,
  });

  Widget _buildSeeAllCard(BuildContext context) {
    return TVFocusable(
      onPressed: onSeeAll,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        height: 195,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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
    // Take at most 10 items
    final top10 = movies.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top 10 Phim Trong Tuần',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
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

        // Carousel List
        SizedBox(
          height: 250,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            cacheExtent: 600,
            itemCount: top10.length + (isWide && onSeeAll != null ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              if (index == top10.length) {
                return _buildSeeAllCard(context);
              }

              final movie = top10[index];
              final ratingVal = movie.voteAverage > 0 ? movie.voteAverage.toStringAsFixed(1) : (movie.quality.isNotEmpty ? movie.quality : 'FHD');

              return RepaintBoundary(
                child: TVFocusable(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(slug: movie.slug),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            CachedPosterImage(
                              imageUrl: movie.fullPosterUrl,
                              width: 140,
                              height: 195,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            // Top Rating Badge (Movix Red)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: RatingBadge(
                                rating: ratingVal,
                                isRed: true,
                              ),
                            ),
                            // Ranking badge
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary, width: 1),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          movie.episodeCurrent.isNotEmpty ? movie.episodeCurrent : '${movie.year}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
