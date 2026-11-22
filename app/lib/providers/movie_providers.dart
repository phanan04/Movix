import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/phim_api_service.dart';
import '../core/models/movie_model.dart';

final apiServiceProvider = Provider<PhimApiService>((ref) {
  return PhimApiService();
});

// Phim mới cập nhật (Trang chủ)
final newUpdatesProvider = FutureProvider<List<MovieItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getNewUpdates(page: 1);
});

// Top 10 Phim Chiếu Rạp Hot trong tuần
final topTenMoviesProvider = FutureProvider<List<MovieItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getMoviesByType('phim-chieu-rap', page: 1, limit: 10);
});

// Phim Bộ Đang Hot
final seriesMoviesProvider = FutureProvider<List<MovieItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getMoviesByType('phim-bo', page: 1, limit: 12);
});

// Phim Lẻ Đáng Xem
final singleMoviesProvider = FutureProvider<List<MovieItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getMoviesByType('phim-le', page: 1, limit: 12);
});

// Hoạt Hình / Anime
final animeMoviesProvider = FutureProvider<List<MovieItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getMoviesByType('hoat-hinh', page: 1, limit: 12);
});

// TV Shows / Gameshows
final tvShowsMoviesProvider = FutureProvider<List<MovieItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getMoviesByType('tv-shows', page: 1, limit: 12);
});

// Explore Filter State Model
class ExploreFilterState {
  final String type; // 'all', 'phim-le', 'phim-bo', 'phim-chieu-rap', 'hoat-hinh', 'tv-shows'
  final String category; // 'all' or slug (26 thể loại)
  final String region; // 'all' or slug (36 quốc gia)
  final String year; // 'all' or year string ('2026', '2025', ..., '1970')
  final String lang; // 'all', 'vietsub', 'thuyet-minh', 'long-tieng'
  final String sortField; // 'modified.time', '_id', 'year'
  final String sortType; // 'desc', 'asc'

  const ExploreFilterState({
    this.type = 'all',
    this.category = 'all',
    this.region = 'all',
    this.year = 'all',
    this.lang = 'all',
    this.sortField = 'modified.time',
    this.sortType = 'desc',
  });

  bool get hasActiveFilter =>
      type != 'all' ||
      category != 'all' ||
      region != 'all' ||
      year != 'all' ||
      lang != 'all' ||
      sortField != 'modified.time' ||
      sortType != 'desc';

  ExploreFilterState copyWith({
    String? type,
    String? category,
    String? region,
    String? year,
    String? lang,
    String? sortField,
    String? sortType,
  }) {
    return ExploreFilterState(
      type: type ?? this.type,
      category: category ?? this.category,
      region: region ?? this.region,
      year: year ?? this.year,
      lang: lang ?? this.lang,
      sortField: sortField ?? this.sortField,
      sortType: sortType ?? this.sortType,
    );
  }
}

class ExploreFilterNotifier extends Notifier<ExploreFilterState> {
  @override
  ExploreFilterState build() => const ExploreFilterState();

  void updateFilter({
    String? type,
    String? category,
    String? region,
    String? year,
    String? lang,
    String? sortField,
    String? sortType,
  }) {
    state = state.copyWith(
      type: type,
      category: category,
      region: region,
      year: year,
      lang: lang,
      sortField: sortField,
      sortType: sortType,
    );
  }

  void resetFilter() {
    state = const ExploreFilterState();
  }
}

final exploreFilterProvider = NotifierProvider<ExploreFilterNotifier, ExploreFilterState>(() {
  return ExploreFilterNotifier();
});

// Danh sách phim trong Explore Tab with REAL multi-dimensional filters & sorting
final exploreMoviesProvider = FutureProvider<List<MovieItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final filter = ref.watch(exploreFilterProvider);

  // Nếu chọn sortField là 'rating' hoặc 'popular', gọi API với 'modified.time' rồi sắp xếp thêm ở client
  final apiSortField = (filter.sortField == 'rating' || filter.sortField == 'popular')
      ? 'modified.time'
      : filter.sortField;

  var movies = await api.getFilteredMovies(
    type: filter.type,
    category: filter.category,
    country: filter.region,
    year: filter.year,
    sortLang: filter.lang,
    sortField: apiSortField,
    sortType: filter.sortType,
    page: 1,
    limit: 36,
  );

  // Post-processing nếu người dùng chọn sắp xếp theo Điểm đánh giá cao hoặc Phổ biến
  if (filter.sortField == 'rating') {
    final list = List<MovieItem>.from(movies);
    list.sort((a, b) => filter.sortType == 'asc'
        ? a.voteAverage.compareTo(b.voteAverage)
        : b.voteAverage.compareTo(a.voteAverage));
    return list;
  } else if (filter.sortField == 'popular') {
    final list = List<MovieItem>.from(movies);
    list.sort((a, b) => filter.sortType == 'asc'
        ? a.year.compareTo(b.year)
        : b.year.compareTo(a.year));
    return list;
  }

  return movies;
});

// Chi tiết phim (theo slug)
final movieDetailProvider = FutureProvider.family<MovieDetail, String>((ref, slug) async {
  final api = ref.watch(apiServiceProvider);
  return api.getMovieDetail(slug);
});

// Search Query Notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

final searchResultsProvider = FutureProvider<List<MovieItem>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final api = ref.watch(apiServiceProvider);
  final filter = ref.watch(exploreFilterProvider);
  return api.searchMovies(
    query,
    category: filter.category,
    country: filter.region,
    year: filter.year,
    limit: 48,
  );
});

// Phim tương tự (theo thể loại)
final similarMoviesProvider = FutureProvider.family<List<MovieItem>, String>((ref, categorySlug) async {
  if (categorySlug.isEmpty) return [];
  final api = ref.watch(apiServiceProvider);
  return api.getMoviesByCategory(categorySlug, page: 1, limit: 15);
});
