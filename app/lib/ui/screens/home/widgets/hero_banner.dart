import 'package:flutter/material.dart';
import '../../../../core/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/cache/user_storage.dart';
import '../../../widgets/cached_poster_image.dart';
import '../../movie_detail/movie_detail_screen.dart';

class HeroBanner extends StatefulWidget {
  final MovieItem? movie;

  const HeroBanner({super.key, this.movie});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final UserStorage _userStorage = UserStorage();

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    if (movie == null) {
      return Container(
        height: 420,
        color: AppColors.surface,
      );
    }

    return RepaintBoundary(
      child: SizedBox(
        height: 420,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            CachedPosterImage(
              imageUrl: movie.fullPosterUrl,
              fit: BoxFit.cover,
              memCacheWidth: 720,
              memCacheHeight: 960,
            ),

            // Top gradient for status bar and top icons
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Color(0xCC181A20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Bottom gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
            ),

            // Bottom Content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    movie.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Categories & Subtitles
                  Text(
                    movie.categoryNames.isNotEmpty
                        ? movie.categoryNames.take(3).join(' • ')
                        : '${movie.originName} • ${movie.year}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons: Play & My List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Play Button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(slug: movie.slug),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                        label: const Text(
                          'Play',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // My List Button
                      ValueListenableBuilder<List<MovieItem>>(
                        valueListenable: _userStorage.myListNotifier,
                        builder: (context, _, __) {
                          final inList = _userStorage.isInMyList(movie.slug);
                          return OutlinedButton.icon(
                            onPressed: () {
                              _userStorage.toggleMyList(movie);
                            },
                            icon: Icon(
                              inList ? Icons.check : Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              inList ? 'Added' : 'My List',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white, width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
