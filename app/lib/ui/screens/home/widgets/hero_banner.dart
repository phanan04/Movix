import 'package:flutter/material.dart';
import '../../../../core/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/cache/user_storage.dart';
import '../../../widgets/cached_poster_image.dart';
import '../../../widgets/tv_focusable.dart';
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    // Khóa chiều cao Hero Banner ở mức 45%–50% chiều cao màn hình (0.48)
    final bannerHeight = screenHeight * 0.48;

    if (movie == null) {
      return Container(
        height: bannerHeight,
        color: AppColors.surface,
      );
    }

    return RepaintBoundary(
      child: SizedBox(
        height: bannerHeight,
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
              left: isWide ? 40 : 16,
              right: isWide ? 40 : 16,
              bottom: 20,
              child: Column(
                crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    movie.name,
                    textAlign: isWide ? TextAlign.left : TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isWide ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                      shadows: const [
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
                    textAlign: isWide ? TextAlign.left : TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons: Xem ngay & + Danh sách (TVFocusable)
                  Row(
                    mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      // Nút "Xem ngay" (Play)
                      TVFocusable(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(slug: movie.slug),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 6),
                              Text(
                                'Xem ngay',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nút "+ Danh sách" (My List)
                      ValueListenableBuilder<List<MovieItem>>(
                        valueListenable: _userStorage.myListNotifier,
                        builder: (context, _, __) {
                          final inList = _userStorage.isInMyList(movie.slug);
                          return TVFocusable(
                            onPressed: () {
                              _userStorage.toggleMyList(movie);
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white70, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    inList ? Icons.check : Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    inList ? 'Đã thêm' : '+ Danh sách',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
