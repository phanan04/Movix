import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../cache/cache_manager.dart';
import '../models/movie_model.dart';

class PhimApiService {
  static const String primaryApi = 'https://phimapi.com';
  static const String nguonCApi = 'https://phim.nguonc.com/api';

  late final Dio _dio;
  final CacheManager _cache = CacheManager();

  PhimApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 6),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MovixFlutter/1.0',
        },
      ),
    );
  }

  // Helper with caching & single-flight dedup
  Future<dynamic> _fetchWithCache(
    String url, {
    Duration maxAge = const Duration(minutes: 10),
  }) async {
    // 1. Check cache first
    final cached = _cache.get(url, maxAge: maxAge);
    if (cached != null) {
      return cached;
    }

    // 2. Fetch with dedup
    return _cache.dedup(url, () async {
      try {
        final res = await _dio.get(url);
        if (res.statusCode == 200 && res.data != null) {
          _cache.set(url, res.data);
          return res.data;
        }
      } catch (e) {
        debugPrint('Fetch error for $url: $e');
        // If error, attempt to return stale cache if available
        final stale = _cache.getStale(url);
        if (stale != null) return stale;
        rethrow;
      }
      throw Exception('Failed to load data from $url');
    });
  }

  // 1. Phim mới cập nhật
  Future<List<MovieItem>> getNewUpdates({int page = 1}) async {
    final url = '$primaryApi/danh-sach/phim-moi-cap-nhat?page=$page';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 5));
    final rawItems = data['items'] as List? ?? [];
    return rawItems.map((e) => MovieItem.fromJson(e)).toList();
  }

  // 2. Phim theo danh mục (phim-bo, phim-le, phim-chieu-rap, hoat-hinh, tv-shows)
  Future<List<MovieItem>> getMoviesByType(String type, {int page = 1, int limit = 20}) async {
    final url = '$primaryApi/v1/api/danh-sach/$type?page=$page&limit=$limit';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 15));
    final rawItems = data['data']?['items'] as List? ?? [];
    return rawItems.map((e) => MovieItem.fromJson(e)).toList();
  }

  // 3. Phim theo thể loại
  Future<List<MovieItem>> getMoviesByCategory(String categorySlug, {int page = 1, int limit = 20}) async {
    final url = '$primaryApi/v1/api/the-loai/$categorySlug?page=$page&limit=$limit';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 15));
    final rawItems = data['data']?['items'] as List? ?? [];
    return rawItems.map((e) => MovieItem.fromJson(e)).toList();
  }

  // 3b. Phim theo quốc gia
  Future<List<MovieItem>> getMoviesByCountry(String countrySlug, {int page = 1, int limit = 24}) async {
    final url = '$primaryApi/v1/api/quoc-gia/$countrySlug?page=$page&limit=$limit';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 15));
    final rawItems = data['data']?['items'] as List? ?? [];
    return rawItems.map((e) => MovieItem.fromJson(e)).toList();
  }

  // 3c. Phim theo năm phát hành
  Future<List<MovieItem>> getMoviesByYear(int year, {int page = 1, int limit = 24}) async {
    final url = '$primaryApi/v1/api/nam/$year?page=$page&limit=$limit';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 15));
    final rawItems = data['data']?['items'] as List? ?? [];
    return rawItems.map((e) => MovieItem.fromJson(e)).toList();
  }

  // 4. Tìm kiếm phim
  Future<List<MovieItem>> searchMovies(String keyword, {int page = 1, int limit = 24}) async {
    if (keyword.trim().isEmpty) return [];
    final encoded = Uri.encodeComponent(keyword.trim());
    final url = '$primaryApi/v1/api/tim-kiem?keyword=$encoded&page=$page&limit=$limit';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 10));
    final rawItems = data['data']?['items'] as List? ?? [];
    return rawItems.map((e) => MovieItem.fromJson(e)).toList();
  }

  // 5. Chi tiết phim đa nguồn (PhimAPI chính + NguonC phụ)
  Future<MovieDetail> getMovieDetail(String slug) async {
    final primaryUrl = '$primaryApi/phim/$slug';

    try {
      final data = await _fetchWithCache(primaryUrl, maxAge: const Duration(minutes: 20));
      return MovieDetail.fromJson(data);
    } catch (e) {
      debugPrint('Primary API error for detail: $e. Trying NguonC fallback...');
      // Fallback to NguonC
      final nguonCUrl = '$nguonCApi/film/$slug';
      final res = await _dio.get(nguonCUrl);
      if (res.statusCode == 200 && res.data != null) {
        final movieData = res.data['movie'];
        if (movieData != null) {
          final servers = <EpisodeServer>[];
          if (movieData['episodes'] is List) {
            for (final s in movieData['episodes']) {
              servers.add(EpisodeServer.fromJson(s));
            }
          }
          return MovieDetail.fromJson(movieData, explicitEpisodes: servers);
        }
      }
      rethrow;
    }
  }
}
