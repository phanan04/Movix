import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/movie_model.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/movie_providers.dart';
import '../../../widgets/cached_poster_image.dart';
import '../../../widgets/tv_focusable.dart';
import '../movie_detail_screen.dart';

class CollectionWidget extends ConsumerWidget {
  final int collectionId;
  final String collectionName;
  final String currentMovieSlug;
  final int? currentTmdbId;

  const CollectionWidget({
    super.key,
    required this.collectionId,
    required this.collectionName,
    required this.currentMovieSlug,
    this.currentTmdbId,
  });

  void _openCollectionPart(BuildContext context, TmdbCollectionPart part) {
    final year = part.releaseDate != null && part.releaseDate!.length >= 4
        ? (int.tryParse(part.releaseDate!.substring(0, 4)) ?? 0)
        : 0;
    final preview = MovieItem(
      id: part.id.toString(),
      name: part.title,
      originName: part.title,
      slug: 'tmdb-${part.id}',
      thumbUrl: part.backdropUrl ?? part.posterUrl ?? '',
      posterUrl: part.posterUrl ?? '',
      year: year,
      episodeCurrent: 'Full',
      quality: part.voteAverage > 0 ? '${part.voteAverage.toStringAsFixed(1)} ★' : 'FHD',
      lang: 'Quốc Tế',
      voteAverage: part.voteAverage,
      tmdbId: part.id,
      tmdbMediaType: 'movie',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(
          slug: preview.slug,
          tmdbId: part.id,
          tmdbMediaType: 'movie',
          previewMovie: preview,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colAsync = ref.watch(movieCollectionProvider(collectionId));

    return colAsync.when(
      data: (collection) {
        if (collection == null || collection.parts.length <= 1) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.collections_bookmark_rounded,
                  size: 16,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Trọn bộ: ${collection.name} (${collection.parts.length} phần)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 175,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: collection.parts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final part = collection.parts[idx];
                  final year = part.releaseDate != null && part.releaseDate!.length >= 4
                      ? part.releaseDate!.substring(0, 4)
                      : '';
                  final isCurrent = currentTmdbId != null && part.id == currentTmdbId;

                  return TVFocusable(
                    onPressed: () => _openCollectionPart(context, part),
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 105,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isCurrent ? 1.5 : 0.8,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (part.posterUrl != null)
                                    CachedPosterImage(
                                      imageUrl: part.posterUrl!,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 220,
                                      memCacheHeight: 320,
                                    )
                                  else
                                    Container(
                                      color: AppColors.surfaceLight,
                                      child: const Center(
                                        child: Icon(Icons.movie_outlined, color: AppColors.textMuted),
                                      ),
                                    ),
                                  if (year.isNotEmpty)
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.75),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          year,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            part.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: isCurrent ? AppColors.primaryLight : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
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
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
