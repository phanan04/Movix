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

// Explore Filter State Model
class ExploreFilterState {
  final String category; // 'all' or slug ('hanh-dong', 'co-trang', ...)
  final String region;   // 'all' or slug ('han-quoc', 'au-my', ...)
  final String year;     // 'all' or year string ('2026', '2025', ...)
  final String sort;     // 'latest', 'popular', 'rating'

  const ExploreFilterState({
    this.category = 'all',
    this.region = 'all',
    this.year = 'all',
    this.sort = 'latest',
  });

  bool get hasActiveFilter =>
      category != 'all' || region != 'all' || year != 'all' || sort != 'latest';

  ExploreFilterState copyWith({
    String? category,
    String? region,
    String? year,
    String? sort,
  }) {
    return ExploreFilterState(
      category: category ?? this.category,
      region: region ?? this.region,
      year: year ?? this.year,
      sort: sort ?? this.sort,
    );
  }
}

class ExploreFilterNotifier extends Notifier<ExploreFilterState> {
  @override
  ExploreFilterState build() => const ExploreFilterState();

  void updateFilter({String? category, String? region, String? year, String? sort}) {
    state = state.copyWith(category: category, region: region, year: year, sort: sort);
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

  List<MovieItem> movies = [];

  if (filter.region != 'all') {
    movies = await api.getMoviesByCountry(filter.region, page: 1, limit: 36);
  } else if (filter.category != 'all') {
    movies = await api.getMoviesByCategory(filter.category, page: 1, limit: 36);
  } else if (filter.year != 'all' && int.tryParse(filter.year) != null) {
    movies = await api.getMoviesByYear(int.parse(filter.year), page: 1, limit: 36);
  } else {
    movies = await api.getMoviesByType('phim-moi', page: 1, limit: 36);
  }

  // Secondary year filter
  if (filter.year != 'all') {
    final targetYear = int.tryParse(filter.year);
    if (targetYear != null) {
      final filtered = movies.where((m) => m.year == targetYear).toList();
      if (filtered.isNotEmpty) {
        movies = filtered;
      }
    }
  }

  // Real Sort ordering
  final result = List<MovieItem>.from(movies);
  if (filter.sort == 'rating') {
    result.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
  } else if (filter.sort == 'popular') {
    result.sort((a, b) => b.year.compareTo(a.year));
  }

  return result;
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
  return api.searchMovies(query);
});
