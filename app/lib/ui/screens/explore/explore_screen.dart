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
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  late FocusNode _focusNode;

  // Explore Pagination State
  List<MovieItem> _exploreMovies = [];
  int _explorePage = 1;
  bool _isLoadingExplore = false;
  bool _hasMoreExplore = true;
  String? _exploreError;

  // Search Pagination State
  List<MovieItem> _searchMovies = [];
  int _searchPage = 1;
  bool _isLoadingSearch = false;
  bool _hasMoreSearch = true;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchExploreMovies(isRefresh: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 350) {
      if (_searchController.text.trim().isNotEmpty) {
        if (!_isLoadingSearch && _hasMoreSearch) {
          _fetchSearchMovies(_searchController.text.trim());
        }
      } else {
        if (!_isLoadingExplore && _hasMoreExplore) {
          _fetchExploreMovies();
        }
      }
    }
  }

  Future<void> _fetchExploreMovies({bool isRefresh = false}) async {
    if (_isLoadingExplore) return;
    if (!isRefresh && !_hasMoreExplore) return;

    final targetPage = isRefresh ? 1 : _explorePage + 1;
    setState(() {
      _isLoadingExplore = true;
      if (isRefresh) {
        _exploreError = null;
      }
    });

    try {
      final api = ref.read(apiServiceProvider);
      final filter = ref.read(exploreFilterProvider);

      final apiSortField = (filter.sortField == 'rating' || filter.sortField == 'popular')
          ? 'modified.time'
          : filter.sortField;

      final newMovies = await api.getFilteredMovies(
        type: filter.type,
        category: filter.category,
        country: filter.region,
        year: filter.year,
        sortLang: filter.lang,
        sortField: apiSortField,
        sortType: filter.sortType,
        page: targetPage,
        limit: 24,
      );

      if (mounted) {
        setState(() {
          _explorePage = targetPage;
          _isLoadingExplore = false;
          if (isRefresh) {
            _exploreMovies = newMovies;
          } else {
            final seenSlugs = _exploreMovies.map((m) => m.slug).toSet();
            for (final m in newMovies) {
              if (seenSlugs.add(m.slug)) {
                _exploreMovies.add(m);
              }
            }
          }
          if (newMovies.length < 24) {
            _hasMoreExplore = false;
          } else {
            _hasMoreExplore = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingExplore = false;
          if (isRefresh && _exploreMovies.isEmpty) {
            _exploreError = e.toString();
          }
        });
      }
    }
  }

  Future<void> _fetchSearchMovies(String query, {bool isRefresh = false}) async {
    final cleanQ = query.trim();
    if (cleanQ.isEmpty) return;
    if (_isLoadingSearch) return;
    if (!isRefresh && !_hasMoreSearch) return;

    final targetPage = isRefresh ? 1 : _searchPage + 1;
    setState(() {
      _isLoadingSearch = true;
      if (isRefresh) {
        _searchError = null;
      }
    });

    try {
      final api = ref.read(apiServiceProvider);
      final filter = ref.read(exploreFilterProvider);

      final newMovies = await api.searchMovies(
        cleanQ,
        category: filter.category,
        country: filter.region,
        year: filter.year,
        page: targetPage,
        limit: 24,
      );

      if (mounted) {
        setState(() {
          _searchPage = targetPage;
          _isLoadingSearch = false;
          if (isRefresh) {
            _searchMovies = newMovies;
          } else {
            final seenSlugs = _searchMovies.map((m) => m.slug).toSet();
            for (final m in newMovies) {
              if (seenSlugs.add(m.slug)) {
                _searchMovies.add(m);
              }
            }
          }
          if (newMovies.length < 12) {
            _hasMoreSearch = false;
          } else {
            _hasMoreSearch = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSearch = false;
          if (isRefresh && _searchMovies.isEmpty) {
            _searchError = e.toString();
          }
        });
      }
    }
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      final q = query.trim();
      ref.read(searchQueryProvider.notifier).setQuery(q);
      if (q.isNotEmpty) {
        _fetchSearchMovies(q, isRefresh: true);
      } else {
        setState(() {
          _searchMovies = [];
          _searchPage = 1;
          _hasMoreSearch = true;
          _searchError = null;
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).setQuery('');
    setState(() {
      _searchMovies = [];
      _searchPage = 1;
      _hasMoreSearch = true;
      _searchError = null;
    });
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
                                _fetchExploreMovies(isRefresh: true);
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
                                  _fetchExploreMovies(isRefresh: true);
                                },
                              ),
                            if (filter.lang != 'all')
                              _buildActiveFilterChip('Ngôn ngữ: ${_getLangLabel(filter.lang)}', () {
                                ref.read(exploreFilterProvider.notifier).updateFilter(lang: 'all');
                                _fetchExploreMovies(isRefresh: true);
                              }),
                            if (filter.type != 'all')
                              _buildActiveFilterChip('Loại: ${_getTypeLabel(filter.type)}', () {
                                ref.read(exploreFilterProvider.notifier).updateFilter(type: 'all');
                                _fetchExploreMovies(isRefresh: true);
                              }),
                            if (filter.category != 'all')
                              _buildActiveFilterChip('Thể loại: ${_getCategoryLabel(filter.category)}', () {
                                ref.read(exploreFilterProvider.notifier).updateFilter(category: 'all');
                                _fetchExploreMovies(isRefresh: true);
                              }),
                            if (filter.region != 'all')
                              _buildActiveFilterChip('Quốc gia: ${_getRegionLabel(filter.region)}', () {
                                ref.read(exploreFilterProvider.notifier).updateFilter(region: 'all');
                                _fetchExploreMovies(isRefresh: true);
                              }),
                            if (filter.year != 'all')
                              _buildActiveFilterChip('Năm: ${filter.year}', () {
                                ref.read(exploreFilterProvider.notifier).updateFilter(year: 'all');
                                _fetchExploreMovies(isRefresh: true);
                              }),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(exploreFilterProvider.notifier).resetFilter();
                        _fetchExploreMovies(isRefresh: true);
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
                    await _fetchSearchMovies(_searchController.text.trim(), isRefresh: true);
                  } else {
                    await _fetchExploreMovies(isRefresh: true);
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
    return _buildLazyMovieGrid(
      movies: _searchMovies,
      isLoading: _isLoadingSearch,
      hasMore: _hasMoreSearch,
      error: _searchError,
      onRetry: () => _fetchSearchMovies(_searchController.text.trim(), isRefresh: true),
      emptyMessage: 'Không tìm thấy phim phù hợp với từ khóa "${_searchController.text.trim()}"',
    );
  }

  Widget _buildCategoryMovies() {
    return _buildLazyMovieGrid(
      movies: _exploreMovies,
      isLoading: _isLoadingExplore,
      hasMore: _hasMoreExplore,
      error: _exploreError,
      onRetry: () => _fetchExploreMovies(isRefresh: true),
      emptyMessage: 'Không có phim nào thỏa mãn bộ lọc hiện tại',
    );
  }

  Widget _buildLazyMovieGrid({
    required List<MovieItem> movies,
    required bool isLoading,
    required bool hasMore,
    required String? error,
    required VoidCallback onRetry,
    required String emptyMessage,
  }) {
    if (isLoading && movies.isEmpty) {
      return _buildGridSkeleton();
    }

    if (error != null && movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.amberAccent),
            const SizedBox(height: 12),
            Text('Không thể tải dữ liệu: $error', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    if (movies.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1000
            ? 5
            : (constraints.maxWidth >= 720
                ? 4
                : (constraints.maxWidth >= 480 ? 3 : 2));

        return CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return GridMovieCard(movie: movies[index]);
                  },
                  childCount: movies.length,
                ),
              ),
            ),

            // Loading More Spinner indicator
            if (isLoading && movies.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Đang tải thêm phim...',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Truly End-of-List notice (Thông báo khi kéo xuống hết danh sách thật sự)
            if (!hasMore && movies.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 90),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Đã tải hết danh sách (${movies.length} phim)',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bạn đã khám phá toàn bộ phim phù hợp với từ khóa & bộ lọc hiện tại',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // Extra bottom padding if more items are available
            if (hasMore && !isLoading)
              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              ),
          ],
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
