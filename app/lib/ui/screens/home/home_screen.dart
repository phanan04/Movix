import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/movie_providers.dart';
import '../../widgets/shimmer_loading.dart';
import 'notification_screen.dart';
import 'widgets/hero_banner.dart';
import 'widgets/top_ten_carousel.dart';
import 'widgets/movie_carousel.dart';

class HomeScreen extends ConsumerWidget {
  final VoidCallback? onSearchTap;

  const HomeScreen({super.key, this.onSearchTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isTabletLandscape = width >= 720;

    final newUpdatesAsync = ref.watch(newUpdatesProvider);
    final topTenAsync = ref.watch(topTenMoviesProvider);
    final seriesAsync = ref.watch(seriesMoviesProvider);
    final singleAsync = ref.watch(singleMoviesProvider);
    final animeAsync = ref.watch(animeMoviesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      // Pinned Top Header on Mobile; On Tablet Landscape, controls live in the sidebar
      appBar: !isTabletLandscape
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 16,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Movix',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Tìm kiếm',
                  onPressed: onSearchTap,
                  icon: const Icon(Icons.search, color: Colors.white, size: 24),
                ),
                IconButton(
                  tooltip: 'Thông báo',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationScreen()),
                    );
                  },
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(newUpdatesProvider);
          ref.invalidate(topTenMoviesProvider);
          ref.invalidate(seriesMoviesProvider);
          ref.invalidate(singleMoviesProvider);
          ref.invalidate(animeMoviesProvider);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Hero Banner
            SliverToBoxAdapter(
              child: newUpdatesAsync.when(
                data: (movies) => HeroBanner(
                  movie: movies.isNotEmpty ? movies.first : null,
                ),
                loading: () => const ShimmerSkeleton(
                  width: double.infinity,
                  height: 420,
                  borderRadius: 0,
                ),
                error: (_, __) => const SizedBox(height: 420),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 2. Top 10 Movies This Week
            SliverToBoxAdapter(
              child: topTenAsync.when(
                data: (movies) => TopTenCarousel(
                  movies: movies,
                  onSeeAll: onSearchTap,
                ),
                loading: () => const MovieCarouselSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // 3. New Releases
            SliverToBoxAdapter(
              child: newUpdatesAsync.when(
                data: (movies) => MovieCarouselSection(
                  title: 'New Releases',
                  movies: movies.skip(1).toList(),
                  onSeeAll: onSearchTap,
                ),
                loading: () => const MovieCarouselSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // 4. Series Movies (Phim Bộ)
            SliverToBoxAdapter(
              child: seriesAsync.when(
                data: (movies) => MovieCarouselSection(
                  title: 'Phim Bộ Đang Hot',
                  movies: movies,
                  onSeeAll: onSearchTap,
                ),
                loading: () => const MovieCarouselSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // 5. Single Movies (Phim Lẻ)
            SliverToBoxAdapter(
              child: singleAsync.when(
                data: (movies) => MovieCarouselSection(
                  title: 'Phim Lẻ Thịnh Hành',
                  movies: movies,
                  onSeeAll: onSearchTap,
                ),
                loading: () => const MovieCarouselSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // 6. Anime & Cartoons
            SliverToBoxAdapter(
              child: animeAsync.when(
                data: (movies) => MovieCarouselSection(
                  title: 'Anime & Hoạt Hình',
                  movies: movies,
                  onSeeAll: onSearchTap,
                ),
                loading: () => const MovieCarouselSkeleton(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 90)), // Bottom padding
          ],
        ),
      ),
    );
  }
}
