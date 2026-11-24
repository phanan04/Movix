import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/movie_providers.dart';
import '../../../widgets/cached_poster_image.dart';

class MovieReviewsWidget extends ConsumerStatefulWidget {
  final MovieDetail movie;

  const MovieReviewsWidget({super.key, required this.movie});

  @override
  ConsumerState<MovieReviewsWidget> createState() => _MovieReviewsWidgetState();
}

class _MovieReviewsWidgetState extends ConsumerState<MovieReviewsWidget> {
  final Set<String> _expandedReviewIds = {};

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(movieReviewsProvider(widget.movie));

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10, width: 0.8),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rate_review_outlined, color: Colors.white38, size: 36),
                  SizedBox(height: 10),
                  Text(
                    'Chưa có bài phê bình quốc tế nào từ TMDb.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, idx) {
            final review = reviews[idx];
            final isExpanded = _expandedReviewIds.contains(review.id);
            final formattedDate = review.createdAt.length >= 10
                ? review.createdAt.substring(0, 10)
                : review.createdAt;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author header
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: ClipOval(
                          child: (review.avatarUrl != null && review.avatarUrl!.isNotEmpty)
                              ? CachedPosterImage(
                                  imageUrl: review.avatarUrl!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 80,
                                  memCacheHeight: 80,
                                )
                              : Center(
                                  child: Text(
                                    review.author.isNotEmpty ? review.author[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Name & TMDb critic badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    review.author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF01B4E4).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: const Color(0xFF01B4E4).withValues(alpha: 0.5),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: const Text(
                                    'TMDb Critic',
                                    style: TextStyle(
                                      color: Color(0xFF01B4E4),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (formattedDate.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Rating star
                      if (review.rating != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F222A),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF35383F), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                              const SizedBox(width: 3),
                              Text(
                                '${review.rating!.toStringAsFixed(review.rating! % 1 == 0 ? 0 : 1)}/10',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Review content
                  Text(
                    review.content,
                    maxLines: isExpanded ? 500 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),

                  // Expand / Collapse button
                  if (review.content.length > 200) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedReviewIds.remove(review.id);
                          } else {
                            _expandedReviewIds.add(review.id);
                          }
                        });
                      },
                      child: Text(
                        isExpanded ? 'Thu gọn' : 'Đọc toàn bộ bài đánh giá',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
