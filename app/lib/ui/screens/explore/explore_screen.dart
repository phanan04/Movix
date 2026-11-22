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
  final FocusNode? focusNode;
  const ExploreScreen({super.key, this.focusNode});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
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
      case 'phim-vietsub': return 'Vietsub';
      case 'phim-thuyet-minh': return 'Thuyết Minh';
      case 'phim-long-tieng': return 'Lồng Tiếng';
      case 'phim-sap-chieu': return 'Sắp Chiếu';
      default: return slug;
    }
  }

  String _getCategoryLabel(String slug) {
    switch (slug) {
      case 'am-nhac': return 'Âm Nhạc';
      case 'bi-an': return 'Bí Ẩn';
      case 'chien-tranh': return 'Chiến Tranh';
      case 'chinh-kich': return 'Chính Kịch';
      case 'co-trang': return 'Cổ Trang';
      case 'gia-dinh': return 'Gia Đình';
      case 'hai-huoc': return 'Hài Hước';
      case 'hanh-dong': return 'Hành Động';
      case 'hinh-su': return 'Hình Sự';
      case 'hoc-duong': return 'Học Đường';
      case 'khoa-hoc': return 'Khoa Học';
      case 'kinh-di': return 'Kinh Dị';
      case 'kinh-dien': return 'Kinh Điển';
      case 'lich-su': return 'Lịch Sử';
      case 'mien-tay': return 'Miền Tây';
      case 'phim-18': return 'Phim 18+';
      case 'phim-ngan': return 'Phim Ngắn';
      case 'phieu-luu': return 'Phiêu Lưu';
      case 'tai-lieu': return 'Tài Liệu';
      case 'tam-ly': return 'Tâm Lý';
      case 'than-thoai': return 'Thần Thoại';
      case 'the-thao': return 'Thể Thao';
      case 'tinh-cam': return 'Tình Cảm';
      case 'tre-em': return 'Trẻ Em';
      case 'vien-tuong': return 'Viễn Tưởng';
      case 'vo-thuat': return 'Võ Thuật';
      case 'hoat-hinh': return 'Hoạt Hình';
      default: return slug;
    }
  }

  String _getRegionLabel(String slug) {
    switch (slug) {
      case 'anh': return 'Anh';
      case 'ba-lan': return 'Ba Lan';
      case 'brazil': return 'Brazil';
      case 'bo-dao-nha': return 'Bồ Đào Nha';
      case 'canada': return 'Canada';
      case 'chau-phi': return 'Châu Phi';
      case 'ha-lan': return 'Hà Lan';
      case 'han-quoc': return 'Hàn Quốc';
      case 'hong-kong': return 'Hồng Kông';
      case 'indonesia': return 'Indonesia';
      case 'malaysia': return 'Malaysia';
      case 'mexico': return 'Mexico';
      case 'na-uy': return 'Na Uy';
      case 'nam-phi': return 'Nam Phi';
      case 'nga': return 'Nga';
      case 'nhat-ban': return 'Nhật Bản';
      case 'philippines': return 'Philippines';
      case 'phap': return 'Pháp';
      case 'quoc-gia-khac': return 'Quốc Gia Khác';
      case 'thai-lan': return 'Thái Lan';
      case 'tho-nhi-ky': return 'Thổ Nhĩ Kỳ';
      case 'thuy-si': return 'Thụy Sĩ';
      case 'thuy-dien': return 'Thụy Điển';
      case 'trung-quoc': return 'Trung Quốc';
      case 'tay-ban-nha': return 'Tây Ban Nha';
      case 'uae': return 'UAE';
      case 'ukraina': return 'Ukraina';
      case 'viet-nam': return 'Việt Nam';
      case 'au-my': return 'Âu Mỹ';
      case 'uc': return 'Úc';
      case 'y': return 'Ý';
      case 'dan-mach': return 'Đan Mạch';
      case 'dai-loan': return 'Đài Loan';
      case 'duc': return 'Đức';
      case 'a-rap-xe-ut': return 'Ả Rập Xê Út';
      case 'an-do': return 'Ấn Độ';
      default: return slug;
    }
  }

  String _getSortFieldLabel(String field) {
    switch (field) {
      case 'modified.time': return 'Cập nhật';
      case '_id': return 'Thời gian đăng';
      case 'year': return 'Năm sản xuất';
      case 'popular': return 'Phổ biến';
      case 'rating': return 'Điểm cao';
      default: return field;
    }
  }

  String _getLangLabel(String lang) {
    switch (lang) {
      case 'vietsub': return 'Vietsub';
      case 'thuyet-minh': return 'Thuyết Minh';
      case 'long-tieng': return 'Lồng Tiếng';
      default: return lang;
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
                              focusNode: _focusNode,
                              onChanged: _onSearchChanged,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Tìm kiếm tên phim (tiếng Việt, tiếng Anh)...',
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
                            SortFilterBottomSheet.show(
                              context,
                              initialFilters: {
                                'sort_field': filter.sortField,
                                'sort_type': filter.sortType,
                                'lang': filter.lang,
                                'type': filter.type,
                                'category': filter.category,
                                'region': filter.region,
                                'year': filter.year,
                              },
                              onApply: (filters) {
                                ref.read(exploreFilterProvider.notifier).updateFilter(
                                  sortField: filters['sort_field'],
                                  sortType: filters['sort_type'],
                                  lang: filters['lang'],
                                  type: filters['type'],
                                  category: filters['category'],
                                  region: filters['region'],
                                  year: filters['year'],
                                );
                              },
                            );
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
                            if (filter.sortField != 'modified.time' || filter.sortType != 'desc')
                              _buildActiveFilterChip(
                                'Sắp xếp: ${_getSortFieldLabel(filter.sortField)} (${filter.sortType == 'desc' ? 'Mới nhất' : 'Cũ nhất'})',
                                () {
                                  ref.read(exploreFilterProvider.notifier).updateFilter(
                                    sortField: 'modified.time',
                                    sortType: 'desc',
                                  );
                                },
                              ),
                            if (filter.lang != 'all')
                              _buildActiveFilterChip('Ngôn ngữ: ${_getLangLabel(filter.lang)}', () {
                                ref.read(exploreFilterProvider.notifier).updateFilter(lang: 'all');
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
                              _buildActiveFilterChip('Quốc gia: ${_getRegionLabel(filter.region)}', () {
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
