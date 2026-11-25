import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/movie_providers.dart';
import '../../widgets/cached_poster_image.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/tv_focusable.dart';
import '../actor/actor_profile_screen.dart';
import 'notification_screen.dart';
import 'widgets/hero_banner.dart';
import 'widgets/continue_watching_carousel.dart';
import 'widgets/top_ten_carousel.dart';
import 'widgets/movie_carousel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSearchTap;
  final ScrollController? scrollController;
  final bool hasOverlayRail;

  const HomeScreen({
    super.key,
    this.onSearchTap,
    this.scrollController,
    this.hasOverlayRail = false,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTabletLandscape = width >= 600;

    final currentMode = ref.watch(appSourceModeProvider);
    final tmdbTrendingAsync = currentMode == AppSourceMode.tmdb
        ? ref.watch(trendingCategoryMoviesProvider(TrendingHubCategory.allWeek))
        : null;
    final newUpdatesAsync = currentMode == AppSourceMode.kkphim
        ? ref.watch(newUpdatesProvider)
        : null;
    final topTenAsync = currentMode == AppSourceMode.kkphim
        ? ref.watch(topTenMoviesProvider)
        : null;
    final seriesAsync = currentMode == AppSourceMode.kkphim
        ? ref.watch(seriesMoviesProvider)
        : null;
    final singleAsync = currentMode == AppSourceMode.kkphim
        ? ref.watch(singleMoviesProvider)
        : null;
    final animeAsync = currentMode == AppSourceMode.kkphim
        ? ref.watch(animeMoviesProvider)
        : null;
    final tvShowsAsync = currentMode == AppSourceMode.kkphim
        ? ref.watch(tvShowsMoviesProvider)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: !isTabletLandscape,
      appBar: !isTabletLandscape
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 16,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
              title: _buildMobileSourceSwitcher(currentMode),
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.8),
                  ),
                  child: IconButton(
                    tooltip: 'Tìm kiếm',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: widget.onSearchTap,
                    icon: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.8),
                  ),
                  child: IconButton(
                    tooltip: 'Thông báo',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      );
                    },
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
              ],
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(trendingCategoryMoviesProvider);
          ref.invalidate(trendingPersonsProvider);
          ref.invalidate(newUpdatesProvider);
          ref.invalidate(topTenMoviesProvider);
          ref.invalidate(seriesMoviesProvider);
          ref.invalidate(singleMoviesProvider);
          ref.invalidate(animeMoviesProvider);
          ref.invalidate(tvShowsMoviesProvider);
        },
        child: MediaQuery.removePadding(
          context: context,
          removeTop: !isTabletLandscape,
          child: CustomScrollView(
            controller: widget.scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
            // 1. Hero Banner phù hợp với Nguồn đang chọn (TMDb / KKPhim)
            SliverToBoxAdapter(
              child: currentMode == AppSourceMode.tmdb
                  ? tmdbTrendingAsync!.when(
                      data: (movies) => HeroBanner(
                        movie: movies.isNotEmpty ? movies.first : null,
                        hasOverlayRail: widget.hasOverlayRail,
                      ),
                      loading: () => ShimmerSkeleton(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.48,
                        borderRadius: 0,
                      ),
                      error: (_, __) => SizedBox(height: MediaQuery.of(context).size.height * 0.48),
                    )
                  : newUpdatesAsync!.when(
                      data: (movies) => HeroBanner(
                        movie: movies.isNotEmpty ? movies.first : null,
                        hasOverlayRail: widget.hasOverlayRail,
                      ),
                      loading: () => ShimmerSkeleton(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.48,
                        borderRadius: 0,
                      ),
                      error: (_, __) => SizedBox(height: MediaQuery.of(context).size.height * 0.48),
                    ),
            ),

            SliverPadding(
              padding: EdgeInsets.only(left: widget.hasOverlayRail ? 64 : 0),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: 14),

                  // 2. Tiếp tục xem (Dùng chung cho cả 2 chế độ TMDb và KKPhim)
                  const ContinueWatchingCarousel(),

                  const SizedBox(height: 18),

                  // 3. Nội dung danh mục hiển thị theo Chế độ Nguồn được chọn:
                  if (currentMode == AppSourceMode.tmdb) ...[
                    // ==========================================
                    // CHUYÊN TRANG TMDb BOM TẤN QUỐC TẾ (ĐẦY ĐỦ 5 HÀNG)
                    // ==========================================
                    _buildTrendingMovieSection(
                      title: 'Xu Hướng Toàn Cầu Tuần Này',
                      category: TrendingHubCategory.allWeek,
                      skipFirst: true,
                    ),
                    const SizedBox(height: 20),

                    _buildTrendingMovieSection(
                      title: 'Bom Tấn Điện Ảnh Quốc Tế',
                      category: TrendingHubCategory.movies,
                    ),
                    const SizedBox(height: 20),

                    _buildTrendingMovieSection(
                      title: 'Series Truyền Hình Quốc Tế',
                      category: TrendingHubCategory.series,
                    ),
                    const SizedBox(height: 20),

                    _buildTrendingMovieSection(
                      title: 'Gây Sốt Trong 24 Giờ Qua',
                      category: TrendingHubCategory.allDay,
                    ),
                    const SizedBox(height: 20),

                    _buildTrendingPersonsSection(),
                    const SizedBox(height: 20),
                  ] else ...[
                    // ==========================================
                    // CHUYÊN TRANG KKPHIM VIETSUB & CHÂU Á (ĐẦY ĐỦ 6 HÀNG)
                    // ==========================================
                    newUpdatesAsync!.when(
                      data: (movies) => MovieCarouselSection(
                        title: 'Phim Mới Cập Nhật',
                        movies: movies.skip(1).toList(),
                        onSeeAll: widget.onSearchTap,
                      ),
                      loading: () => const MovieCarouselSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    topTenAsync!.when(
                      data: (movies) => TopTenCarousel(
                        movies: movies,
                        onSeeAll: widget.onSearchTap,
                      ),
                      loading: () => const MovieCarouselSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    seriesAsync!.when(
                      data: (movies) => MovieCarouselSection(
                        title: 'Phim Bộ Đang Hot',
                        movies: movies,
                        onSeeAll: widget.onSearchTap,
                      ),
                      loading: () => const MovieCarouselSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    singleAsync!.when(
                      data: (movies) => MovieCarouselSection(
                        title: 'Phim Lẻ Thịnh Hành',
                        movies: movies,
                        onSeeAll: widget.onSearchTap,
                      ),
                      loading: () => const MovieCarouselSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    animeAsync!.when(
                      data: (movies) => MovieCarouselSection(
                        title: 'Anime & Hoạt Hình',
                        movies: movies,
                        onSeeAll: widget.onSearchTap,
                      ),
                      loading: () => const MovieCarouselSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    tvShowsAsync!.when(
                      data: (movies) => MovieCarouselSection(
                        title: 'TV Shows & Gameshow',
                        movies: movies,
                        onSeeAll: widget.onSearchTap,
                      ),
                      loading: () => const MovieCarouselSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 110), // Bottom padding for floating pill bar
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMobileSourceSwitcher(AppSourceMode currentMode) {
    return PopupMenuButton<AppSourceMode>(
      tooltip: 'Chuyển nguồn: TMDb / KKPhim',
      offset: const Offset(0, 48),
      constraints: const BoxConstraints(minWidth: 130, maxWidth: 160),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x28FFFFFF), width: 0.8),
      ),
      color: const Color(0xFF16181F),
      elevation: 12,
      initialValue: currentMode,
      onSelected: (mode) {
        ref.read(appSourceModeProvider.notifier).state = mode;
      },
      itemBuilder: (context) => [
        PopupMenuItem<AppSourceMode>(
          value: AppSourceMode.tmdb,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'TMDb',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: currentMode == AppSourceMode.tmdb ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14.5,
                ),
              ),
              const Spacer(),
              if (currentMode == AppSourceMode.tmdb)
                const Icon(Icons.check, color: AppColors.primary, size: 18),
            ],
          ),
        ),
        PopupMenuItem<AppSourceMode>(
          value: AppSourceMode.kkphim,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'KKPhim',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: currentMode == AppSourceMode.kkphim ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14.5,
                ),
              ),
              const Spacer(),
              if (currentMode == AppSourceMode.kkphim)
                const Icon(Icons.check, color: AppColors.primary, size: 18),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentMode == AppSourceMode.tmdb ? 'TMDb' : 'KKPhim',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hàng phim thịnh hành theo danh mục TMDb
  Widget _buildTrendingMovieSection({
    required String title,
    required TrendingHubCategory category,
    bool skipFirst = false,
  }) {
    final moviesAsync = ref.watch(trendingCategoryMoviesProvider(category));

    return moviesAsync.when(
      data: (movies) {
        final displayMovies = skipFirst ? movies.skip(1).toList() : movies;
        if (displayMovies.isEmpty) return const SizedBox.shrink();
        return MovieCarouselSection(
          title: title,
          movies: displayMovies,
          onSeeAll: widget.onSearchTap,
        );
      },
      loading: () => const MovieCarouselSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Hàng nghệ sĩ / diễn viên đang thịnh hành (TMDb Stars)
  Widget _buildTrendingPersonsSection() {
    final personsAsync = ref.watch(trendingPersonsProvider);

    return personsAsync.when(
      data: (persons) {
        if (persons.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Ngôi Sao Điện Ảnh Thịnh Hành',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 156,
              child: ListView.separated(
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
                      width: 88,
                      child: Column(
                        children: [
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
              ),
            ),
          ],
        );
      },
      loading: () => const MovieCarouselSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
