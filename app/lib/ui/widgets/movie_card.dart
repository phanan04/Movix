import 'package:flutter/material.dart';
import '../../core/models/movie_model.dart';
import '../../core/theme/app_colors.dart';
import 'cached_poster_image.dart';
import 'rating_badge.dart';
import 'tv_focusable.dart';
import '../screens/movie_detail/movie_detail_screen.dart';

class MovieCard extends StatelessWidget {
  final MovieItem movie;
  final double width;
  final double height;
  final String? customBadge;

  const MovieCard({
    super.key,
    required this.movie,
    this.width = 130,
    this.height = 190,
    this.customBadge,
  });

  @override
  Widget build(BuildContext context) {
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
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poster Container
              Stack(
                children: [
                  CachedPosterImage(
                    imageUrl: movie.fullPosterUrl,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  // Rating / Status Badge (top-left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: RatingBadge(
                      rating: customBadge ?? (movie.quality.isNotEmpty ? movie.quality : 'FHD'),
                      isRed: true,
                    ),
                  ),
                  // Year badge (top-right if available)
                  if (movie.year > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: RatingBadge(
                        rating: '${movie.year}',
                        isRed: false,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Movie Title
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
              // Episode or subtitle
              Text(
                movie.episodeCurrent.isNotEmpty
                    ? movie.episodeCurrent
                    : (movie.categoryNames.isNotEmpty ? movie.categoryNames.first : movie.originName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
  }
}

class GridMovieCard extends StatelessWidget {
  final MovieItem movie;

  const GridMovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(slug: movie.slug),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster fills available vertical height of the grid cell
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedPosterImage(
                    imageUrl: movie.fullPosterUrl,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // Rating / Quality Badge (top-left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: RatingBadge(
                      rating: movie.quality.isNotEmpty ? movie.quality : 'FHD',
                      isRed: true,
                    ),
                  ),
                  // Year badge (top-right)
                  if (movie.year > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: RatingBadge(
                        rating: '${movie.year}',
                        isRed: false,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Movie Title
            Text(
              movie.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            // Subtitle
            Text(
              movie.episodeCurrent.isNotEmpty
                  ? movie.episodeCurrent
                  : (movie.categoryNames.isNotEmpty ? movie.categoryNames.first : '${movie.year}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
