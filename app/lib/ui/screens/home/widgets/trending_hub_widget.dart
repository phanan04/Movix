import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/movie_providers.dart';
import '../../../widgets/cached_poster_image.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/tv_focusable.dart';
import '../../actor/actor_profile_screen.dart';
import '../../movie_detail/movie_detail_screen.dart';

class TrendingHubWidget extends ConsumerStatefulWidget {
  final VoidCallback? onSeeAll;

  const TrendingHubWidget({super.key, this.onSeeAll});

  @override
  ConsumerState<TrendingHubWidget> createState() => _TrendingHubWidgetState();
}

class _TrendingHubWidgetState extends ConsumerState<TrendingHubWidget> {
  TrendingHubCategory _selectedCategory = TrendingHubCategory.allWeek;

  final List<({TrendingHubCategory category, String label, IconData icon})> _tabs = const [
    (category: TrendingHubCategory.allWeek, label: 'Tất cả (Tuần)', icon: Icons.star_rounded),
    (category: TrendingHubCategory.allDay, label: 'Hôm nay (24h)', icon: Icons.bolt_rounded),
    (category: TrendingHubCategory.movies, label: 'Phim lẻ', icon: Icons.movie_rounded),
    (category: TrendingHubCategory.series, label: 'Phim bộ', icon: Icons.tv_rounded),
    (category: TrendingHubCategory.people, label: 'Nghệ sĩ Hot', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Header: Tiêu đề + Huy hiệu TMDb + Nút Xem tất cả
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 6),
              const Text(
                'Bảng Xếp Hạng Thịnh Hành',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primaryBorder, width: 0.8),
                ),
                child: const Text(
                  'TMDb',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.onSeeAll != null)
                GestureDetector(
                  onTap: widget.onSeeAll,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Filter Pills Bar (Thanh chọn tab 1 chạm)
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final tab = _tabs[idx];
              final isSelected = _selectedCategory == tab.category;

              return TVFocusable(
                onPressed: () {
                  if (_selectedCategory != tab.category) {
                    setState(() {
                      _selectedCategory = tab.category;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.12),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 14,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // 3. Nội dung theo tab đã chọn (Chuyển đổi mượt mà)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _selectedCategory == TrendingHubCategory.people
              ? _buildTrendingPersonsList()
              : _buildTrendingMoviesList(_selectedCategory),
        ),
      ],
    );
  }

  /// Danh sách Phim thịnh hành kèm thứ hạng #1, #2, #3...
  Widget _buildTrendingMoviesList(TrendingHubCategory category) {
    final moviesAsync = ref.watch(trendingCategoryMoviesProvider(category));

    return SizedBox(
      key: ValueKey(category),
      height: 200,
      child: moviesAsync.when(
        data: (movies) {
          if (movies.isEmpty) {
            return const Center(
              child: Text(
                'Không có dữ liệu xu hướng lúc này.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final movie = movies[idx];
              final rank = idx + 1;

              return TVFocusable(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(
                        slug: movie.slug,
                        tmdbId: movie.tmdbId,
                        tmdbMediaType: movie.tmdbMediaType,
                        previewMovie: movie,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 115,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster thẻ phim kèm Rank Badge #1, #2...
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedPosterImage(
                                imageUrl: movie.fullPosterUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 230,
                                memCacheHeight: 320,
                              ),
                              // Rank Badge góc trên bên trái
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: rank <= 3 ? AppColors.primary : Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '#$rank',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              // Chất lượng góc trên bên phải
                              if (movie.quality.isNotEmpty)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      movie.quality,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Tên phim
                      Text(
                        movie.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Năm / Tập
                      Text(
                        movie.year > 0 ? '${movie.year}' : (movie.episodeCurrent.isNotEmpty ? movie.episodeCurrent : 'Mới'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const MovieCarouselSkeleton(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  /// Danh sách Nghệ sĩ / Diễn viên hot tuần này
  Widget _buildTrendingPersonsList() {
    final personsAsync = ref.watch(trendingPersonsProvider);

    return SizedBox(
      key: const ValueKey('trending_persons'),
      height: 165,
      child: personsAsync.when(
        data: (persons) {
          if (persons.isEmpty) {
            return const Center(
              child: Text(
                'Không có dữ liệu nghệ sĩ thịnh hành.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: persons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final person = persons[idx];

              return TVFocusable(
                onPressed: () {
                  if (person.id > 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActorProfileScreen(
                          personId: person.id,
                          name: person.name,
                          profileUrl: person.profileUrl,
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 90,
                  child: Column(
                    children: [
                      // Avatar chân dung bo tròn nổi bật
                      Container(
                        width: 84,
                        height: 104,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 0.8,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: person.profileUrl != null
                              ? CachedPosterImage(
                                  imageUrl: person.profileUrl!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 170,
                                  memCacheHeight: 210,
                                )
                              : const Center(
                                  child: Icon(Icons.person_rounded, color: Colors.white38, size: 36),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Tên diễn viên
                      Text(
                        person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Nghề nghiệp
                      Text(
                        person.character.isNotEmpty ? person.character : 'Diễn viên',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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
          );
        },
        loading: () => const MovieCarouselSkeleton(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
