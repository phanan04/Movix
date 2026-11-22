import 'package:flutter/material.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/cached_poster_image.dart';

class CastListWidget extends StatelessWidget {
  final List<TmdbCast> tmdbCast;
  final List<String> fallbackActors;

  const CastListWidget({
    super.key,
    required this.tmdbCast,
    required this.fallbackActors,
  });

  @override
  Widget build(BuildContext context) {
    if (tmdbCast.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diễn viên & Vai diễn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: tmdbCast.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cast = tmdbCast[index];
                return SizedBox(
                  width: 86,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rectangular Portrait Card (Chuẩn tỉ lệ điện ảnh, bo nhẹ 6px đồng bộ)
                      Container(
                        width: 86,
                        height: 104,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: cast.profileUrl != null
                              ? CachedPosterImage(
                                  imageUrl: cast.profileUrl!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 160,
                                  memCacheHeight: 200,
                                )
                              : const Center(
                                  child: Icon(Icons.person_rounded, color: Colors.white38, size: 32),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Tên diễn viên
                      Text(
                        cast.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Tên nhân vật (vai diễn)
                      if (cast.character.isNotEmpty)
                        Text(
                          cast.character,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (fallbackActors.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diễn viên',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fallbackActors.join(', '),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
