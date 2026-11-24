import 'package:flutter/material.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/cached_poster_image.dart';
import '../../../widgets/tv_focusable.dart';
import '../../actor/actor_profile_screen.dart';

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
                return TVFocusable(
                  onPressed: () {
                    if (cast.id > 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActorProfileScreen(
                            personId: cast.id,
                            name: cast.name,
                            profileUrl: cast.profileUrl,
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
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
            'Diễn viên & Vai diễn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: fallbackActors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final actorName = fallbackActors[index];
                final initials = _getInitials(actorName);
                return TVFocusable(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActorProfileScreen(
                          personId: 0,
                          name: actorName,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 86,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rectangular Card phong cách điện ảnh với Avatar chữ lồng
                        Container(
                          width: 86,
                          height: 104,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF282C35),
                                Color(0xFF181A20),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border, width: 0.8),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 48,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Tên diễn viên
                        Text(
                          actorName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Diễn viên',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
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
    }

    return const SizedBox.shrink();
  }

  String _getInitials(String name) {
    var clean = name.replaceAll(RegExp(r'^(NSND|NSƯT|NSUT|MC)\s+', caseSensitive: false), '').trim();
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'DV';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
