import 'package:flutter/material.dart';
import '../../../../core/cache/user_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/cached_poster_image.dart';
import '../../movie_detail/movie_detail_screen.dart';

class ContinueWatchingCarousel extends StatelessWidget {
  const ContinueWatchingCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<WatchProgress>>(
      valueListenable: UserStorage().historyNotifier,
      builder: (context, historyList, _) {
        if (historyList.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tiếp tục xem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Landscape Carousel
            SizedBox(
              height: 175,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: historyList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final item = historyList[index];
                  final total = item.durationSeconds > 0 ? item.durationSeconds : 1;
                  final progress = (item.positionSeconds / total).clamp(0.03, 1.0);
                  final remainingSecs = (item.durationSeconds - item.positionSeconds).clamp(0, item.durationSeconds);
                  final remainingMins = (remainingSecs / 60).ceil();

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailScreen(slug: item.movieSlug),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 210,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 16:9 Thumbnail with Play Button & Red Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                CachedPosterImage(
                                  imageUrl: item.posterUrl,
                                  width: 210,
                                  height: 118,
                                  fit: BoxFit.cover,
                                ),
                                // Gradient Overlay for contrast
                                Container(
                                  width: 210,
                                  height: 118,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.6),
                                      ],
                                    ),
                                  ),
                                ),
                                // Center Play Icon
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.55),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white38, width: 1),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                                // Bottom Progress Track
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    height: 3.5,
                                    color: Colors.white24,
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: progress,
                                      child: Container(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Movie Title
                          Text(
                            item.movieName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Episode & Remaining time
                          Text(
                            remainingMins > 0
                                ? '${item.episodeName} • Còn $remainingMins phút'
                                : '${item.episodeName} • Đã xem xong',
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
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
