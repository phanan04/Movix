import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/movie_providers.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/shimmer_loading.dart';
import 'widgets/sort_filter_bottom_sheet.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchQueryProvider.notifier).setQuery(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).setQuery('');
  }

  String _getTypeLabel(String slug) {
    switch (slug) {
      case 'phim-le': return 'Phim Lẻ';
      case 'phim-bo': return 'Phim Bộ';
      case 'phim-chieu-rap': return 'Chiếu Rạp';
      case 'hoat-hinh': return 'Hoạt Hình';
      case 'tv-shows': return 'TV Shows';
      default: return slug;
    }
  }

  String _getCategoryLabel(String slug) {
    switch (slug) {
      case 'hanh-dong': return 'Hành Động';
      case 'co-trang': return 'Cổ Trang';
      case 'vien-tuong': return 'Viễn Tưởng';
      case 'kinh-di': return 'Kinh Dị';
      case 'tinh-cam': return 'Tình Cảm';
      case 'hai-huoc': return 'Hài Hước';
      case 'hoat-hinh': return 'Hoạt Hình';
      case 'tam-ly': return 'Tâm Lý';
      case 'vo-thuat': return 'Võ Thuật';
      case 'phieu-luu': return 'Phiêu Lưu';
      case 'than-thoai': return 'Thần Thoại';
      case 'hoc-duong': return 'Học Đường';
      case 'gia-dinh': return 'Gia Đình';
      case 'tai-lieu': return 'Tài Liệu';
      case 'bi-an': return 'Bí Ẩn';
      default: return slug;
    }
  }

  String _getRegionLabel(String slug) {
    switch (slug) {
      case 'han-quoc': return 'Hàn Quốc';
      case 'trung-quoc': return 'Trung Quốc';
      case 'au-my': return 'Âu Mỹ';
      case 'viet-nam': return 'Việt Nam';
      case 'nhat-ban': return 'Nhật Bản';
      default: return slug;
    }
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'rating': return 'Điểm cao';
      case 'popular': return 'Phổ biến';
      case 'latest': return 'Mới nhất';
      default: return sort;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.trim().isNotEmpty;
    final filter = ref.watch(exploreFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Search Bar (Movix Style: Search Input + Red Filter Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Tìm kiếm tên phim, diễn viên...',
                                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: _clearSearch,
                              child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Movix Red Filter Button with active indicator
                  Stack(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                          onPressed: () {
                            SortFilterBottomSheet.show(context, onApply: (filters) {
                              ref.read(exploreFilterProvider.notifier).updateFilter(
                                sort: filters['sort'],
                                type: filters['type'],
                                category: filters['category'],
                                region: filters['region'],
                                year: filters['year'],
                              );
                            });
                          },
                        ),
                      ),
                      if (filter.hasActiveFilter)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Active Filter Summary Bar
            if (filter.hasActiveFilter && !isSearching) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (filter.sort != 'latest')
                              _buildActiveFilterChip('Sắp xếp: ${_getSortLabel(filter.sort)}', () {
                                ref.read(exploreFilterProvider.notifier).updateFilter(sort: 'latest');
                              }),
                            if (filter.type != 'all')
                              _buildActiveFilterChip('Loại: ${_getTypeLabel(filter.type)}', () {
                                ref.read(exploreFilterProvider.notifier).updateFilter(type: 'all');
                              }),
                            if (filter.category != 'all')
                              _buildActiveFilterChip('Thể loại: ${_getCategoryLabel(filter.category)}', () {
                                ref.read(exploreFilterProvider.notifier).updateFilter(category: 'all');
                              }),
                            if (filter.region != 'all')
                              _buildActiveFilterChip('Khu vực: ${_getRegionLabel(filter.region)}', () {
                                ref.read(exploreFilterProvider.notifier).updateFilter(region: 'all');
                              }),
                            if (filter.year != 'all')
                              _buildActiveFilterChip('Năm: ${filter.year}', () {
                                ref.read(exploreFilterProvider.notifier).updateFilter(year: 'all');
                              }),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(exploreFilterProvider.notifier).resetFilter();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text('Xóa lọc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Content Grid: Search Results OR Category Browse (with RefreshIndicator)
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () async {
                  if (isSearching) {
                    return ref.refresh(searchResultsProvider.future);
                  } else {
                    return ref.refresh(exploreMoviesProvider.future);
                  }
                },
                child: isSearching ? _buildSearchResults() : _buildCategoryMovies(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String text, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchAsync = ref.watch(searchResultsProvider);

    return searchAsync.when(
      data: (movies) {
        if (movies.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text(
                  'Không tìm thấy phim phù hợp',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return _buildMovieGrid(movies);
      },
      loading: () => _buildGridSkeleton(),
      error: (e, _) => Center(
        child: Text(
          'Lỗi tìm kiếm: $e',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildCategoryMovies() {
    final exploreAsync = ref.watch(exploreMoviesProvider);

    return exploreAsync.when(
      data: (movies) {
        if (movies.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_alt_off_rounded, size: 64, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text(
                  'Không có phim nào thỏa mãn bộ lọc',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return _buildMovieGrid(movies);
      },
      loading: () => _buildGridSkeleton(),
      error: (e, _) => Center(
        child: Text(
          'Lỗi tải phim: $e',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  // Responsive Grid (2 columns on mobile, 3 on phablets, 4-5 on tablet landscape)
  Widget _buildMovieGrid(List<MovieItem> movies) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1000
            ? 5
            : (constraints.maxWidth >= 720
                ? 4
                : (constraints.maxWidth >= 480 ? 3 : 2));

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          cacheExtent: 600,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.65, // Optimal cinema 2:3 poster ratio + title
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            return GridMovieCard(movie: movies[index]);
          },
        );
      },
    );
  }

  Widget _buildGridSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1000
            ? 5
            : (constraints.maxWidth >= 720
                ? 4
                : (constraints.maxWidth >= 480 ? 3 : 2));

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.65,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            return const ShimmerSkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 16,
            );
          },
        );
      },
    );
  }
}
