import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/phim_api_service.dart';
import '../core/models/movie_model.dart';
import '../core/services/tmdb_service.dart';

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

// TMDb Filter State Model
class TmdbFilterState {
  final String mediaType; // 'all', 'movie', 'tv'
  final String sortBy; // 'popularity.desc', 'vote_average.desc', 'vote_count.desc', 'primary_release_date.desc', 'revenue.desc'
  final String genre; // 'all' or genre ID ('28', '12', ...)
  final String language; // 'all', 'en', 'ko', 'ja', 'zh', 'th', 'fr', 'es', 'de', 'hi', 'vi'
  final String year; // 'all', '2026', '2025', '2024'...
  final double minRating; // 0.0, 8.0, 7.0, 6.0

  const TmdbFilterState({
    this.mediaType = 'movie',
    this.sortBy = 'popularity.desc',
    this.genre = 'all',
    this.language = 'all',
    this.year = 'all',
    this.minRating = 0.0,
  });

  bool get hasActiveFilter =>
      mediaType != 'movie' ||
      sortBy != 'popularity.desc' ||
      genre != 'all' ||
      language != 'all' ||
      year != 'all' ||
      minRating > 0.0;

  TmdbFilterState copyWith({
    String? mediaType,
    String? sortBy,
    String? genre,
    String? language,
    String? year,
    double? minRating,
  }) {
    return TmdbFilterState(
      mediaType: mediaType ?? this.mediaType,
      sortBy: sortBy ?? this.sortBy,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      year: year ?? this.year,
      minRating: minRating ?? this.minRating,
    );
  }
}

class TmdbFilterNotifier extends Notifier<TmdbFilterState> {
  @override
  TmdbFilterState build() => const TmdbFilterState();

  void updateFilter({
    String? mediaType,
    String? sortBy,
    String? genre,
    String? language,
    String? year,
    double? minRating,
  }) {
    state = state.copyWith(
      mediaType: mediaType,
      sortBy: sortBy,
      genre: genre,
      language: language,
      year: year,
      minRating: minRating,
    );
  }

  void resetFilter() {
    state = const TmdbFilterState();
  }
}

final tmdbFilterProvider = NotifierProvider<TmdbFilterNotifier, TmdbFilterState>(
  TmdbFilterNotifier.new,
);

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

// Phim tương tự (TMDb AI Recommendations + Fallback)
final similarMoviesProvider = FutureProvider.family<List<MovieItem>, MovieDetail>((ref, movie) async {
  final api = ref.watch(apiServiceProvider);
  return api.getSimilarMovies(movie);
});

// Hồ sơ diễn viên & phim đã đóng (TMDb Filmography)
final personDetailsProvider = FutureProvider.family<TmdbPersonDetails?, int>((ref, personId) async {
  return TmdbService().getPersonDetails(personId);
});

// Tìm kiếm hồ sơ diễn viên theo tên
final personDetailsByNameProvider = FutureProvider.family<TmdbPersonDetails?, String>((ref, name) async {
  return TmdbService().searchPerson(name);
});

// Trọn bộ sưu tập / Franchise
final movieCollectionProvider = FutureProvider.family<TmdbCollection?, int>((ref, collectionId) async {
  return TmdbService().getCollection(collectionId);
});

// Đánh giá từ cộng đồng quốc tế (Reviews)
final movieReviewsProvider = FutureProvider.family<List<TmdbReview>, MovieDetail>((ref, movie) async {
  if (movie.tmdbId == null || movie.tmdbMediaType == null) return [];
  return TmdbService().getMovieReviews(movie.tmdbId!, movie.tmdbMediaType!);
});

// Chế độ nguồn phim chính của ứng dụng: TMDb hoặc KKPhim
enum AppSourceMode {
  tmdb,
  kkphim,
}

extension AppSourceModeExtension on AppSourceMode {
  String get label {
    switch (this) {
      case AppSourceMode.tmdb:
        return 'TMDb';
      case AppSourceMode.kkphim:
        return 'KKPhim';
    }
  }
}

class AppSourceModeNotifier extends Notifier<AppSourceMode> {
  @override
  AppSourceMode build() => AppSourceMode.tmdb;

  void setMode(AppSourceMode mode) => state = mode;

  @override
  set state(AppSourceMode val) => super.state = val;
}

final appSourceModeProvider = NotifierProvider<AppSourceModeNotifier, AppSourceMode>(
  AppSourceModeNotifier.new,
);

// Các danh mục của Trending Hub (TMDb)
enum TrendingHubCategory {
  allWeek, // 🌟 Tất cả (Tuần)
  allDay,  // ⚡ Hôm nay (24h)
  movies,  // 🎬 Phim lẻ
  series,  // 📺 Phim bộ
  people,  // 🎭 Nghệ sĩ Hot
}

// Provider lấy phim theo danh mục Trending
final trendingCategoryMoviesProvider = FutureProvider.family<List<MovieItem>, TrendingHubCategory>((ref, category) async {
  final api = ref.watch(apiServiceProvider);
  String mediaType = 'all';
  String timeWindow = 'week';

  switch (category) {
    case TrendingHubCategory.allWeek:
      mediaType = 'all';
      timeWindow = 'week';
      break;
    case TrendingHubCategory.allDay:
      mediaType = 'all';
      timeWindow = 'day';
      break;
    case TrendingHubCategory.movies:
      mediaType = 'movie';
      timeWindow = 'week';
      break;
    case TrendingHubCategory.series:
      mediaType = 'tv';
      timeWindow = 'week';
      break;
    case TrendingHubCategory.people:
      return [];
  }

  final titles = await TmdbService().getTrending(mediaType: mediaType, timeWindow: timeWindow);
  if (titles.isEmpty) return [];

  final futures = titles.take(15).map((t) async {
    try {
      final res = await api.searchMovies(t, limit: 1);
      return res.isNotEmpty ? res.first : null;
    } catch (_) {
      return null;
    }
  });

  final list = await Future.wait(futures);
  final seen = <String>{};
  final results = <MovieItem>[];
  for (final m in list) {
    if (m != null && !seen.contains(m.slug)) {
      seen.add(m.slug);
      results.add(m);
    }
  }
  return results;
});

// Provider lấy nghệ sĩ thịnh hành (Trending Persons)
final trendingPersonsProvider = FutureProvider<List<TmdbCast>>((ref) async {
  return TmdbService().getTrendingPersons(timeWindow: 'week');
});

// Phim thịnh hành toàn cầu (TMDb Trending mặc định)
final trendingMoviesProvider = FutureProvider<List<MovieItem>>((ref) async {
  return ref.watch(trendingCategoryMoviesProvider(TrendingHubCategory.allWeek).future);
});
