import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/movie_providers.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/cached_poster_image.dart';
import '../../../widgets/tv_focusable.dart';
import '../movie_detail_screen.dart';

class CollectionWidget extends ConsumerWidget {
  final int collectionId;
  final String collectionName;
  final String currentMovieSlug;

  const CollectionWidget({
    super.key,
    required this.collectionId,
    required this.collectionName,
    required this.currentMovieSlug,
  });

  void _openCollectionPart(BuildContext context, WidgetRef ref, TmdbCollectionPart part) async {
    final api = ref.read(apiServiceProvider);
    AppToast.show(context, 'Đang mở ${part.title}...', icon: Icons.movie_outlined);
    try {
      final res = await api.searchMovies(part.title, limit: 1);
      if (res.isNotEmpty && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(slug: res.first.slug),
          ),
        );
        return;
      }
      if (context.mounted) {
        AppToast.show(context, 'Phần phim "${part.title}" chưa có bản chiếu', icon: Icons.info_outline);
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.show(context, 'Không thể tải phần phim này', icon: Icons.error_outline);
      }
    }
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
                const Icon(Icons.collections_bookmark_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trọn bộ: ${collection.name} (${collection.parts.length} phần)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  final part = collection.parts[idx];
                  final year = part.releaseDate != null && part.releaseDate!.length >= 4
                      ? part.releaseDate!.substring(0, 4)
                      : '';

                  return TVFocusable(
                    onPressed: () => _openCollectionPart(context, ref, part),
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 105,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (part.posterUrl != null)
                                    CachedPosterImage(
                                      imageUrl: part.posterUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    Container(
                                      color: const Color(0xFF1E212A),
                                      child: const Center(
                                        child: Icon(Icons.movie_outlined, color: Colors.white38),
                                      ),
                                    ),
                                  if (year.isNotEmpty)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.75),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          year,
                                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            part.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
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
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
