import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../cache/cache_manager.dart';
import '../models/movie_model.dart';
import '../services/tmdb_service.dart';

class PhimApiService {
  static const String primaryApi = 'https://phimapi.com';
  static const String nguonCApi = 'https://phim.nguonc.com/api';
  static const String vsMovApi = 'https://vsmov.com/api';

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

  // 3d. Bộ lọc đa chiều chuẩn KKPhim v1 danh-sach
  Future<List<MovieItem>> getFilteredMovies({
    String type = 'phim-moi-cap-nhat',
    String? category,
    String? country,
    String? year,
    String? sortLang,
    String? sortField,
    String? sortType,
    int page = 1,
    int limit = 36,
  }) async {
    final listType = (type.isEmpty || type == 'all') ? 'phim-moi-cap-nhat' : type;
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null && category.isNotEmpty && category != 'all') {
      params['category'] = category;
    }
    if (country != null && country.isNotEmpty && country != 'all') {
      params['country'] = country;
    }
    if (year != null && year.isNotEmpty && year != 'all') {
      params['year'] = year;
    }
    if (sortLang != null && sortLang.isNotEmpty && sortLang != 'all') {
      params['sort_lang'] = sortLang;
    }
    if (sortField != null && sortField.isNotEmpty) {
      params['sort_field'] = sortField;
    }
    if (sortType != null && sortType.isNotEmpty) {
      params['sort_type'] = sortType;
    }

    final query = Uri(queryParameters: params).query;
    final url = '$primaryApi/v1/api/danh-sach/$listType?$query';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 5));
    final rawItems = data['data']?['items'] as List? ?? [];
    return rawItems.map((e) => MovieItem.fromJson(e)).toList();
  }

  // 4. Tìm kiếm phim song song (KKPhim + VSMov cùng lúc, gộp kết quả và khử trùng lặp)
  Future<List<MovieItem>> searchMovies(
    String keyword, {
    String? category,
    String? country,
    String? year,
    int page = 1,
    int limit = 48,
  }) async {
    if (keyword.trim().isEmpty) return [];
    final cleanKeyword = keyword.trim();
    final encoded = Uri.encodeComponent(cleanKeyword);

    final params = <String, String>{
      'keyword': cleanKeyword,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null && category.isNotEmpty && category != 'all') {
      params['category'] = category;
    }
    if (country != null && country.isNotEmpty && country != 'all') {
      params['country'] = country;
    }
    if (year != null && year.isNotEmpty && year != 'all') {
      params['year'] = year;
    }

    final query = Uri(queryParameters: params).query;
    final kkPhimUrl = '$primaryApi/v1/api/tim-kiem?$query';
    final vsMovUrl = '$vsMovApi/tim-kiem?keyword=$encoded&page=$page';

    // Chạy song song cả 2 nguồn KKPhim & VSMov
    final results = await Future.wait([
      // Nguồn 1: KKPhim
      _fetchWithCache(kkPhimUrl, maxAge: const Duration(minutes: 5))
          .then<List<MovieItem>>((data) {
        final rawItems = data?['data']?['items'] as List? ?? [];
        return rawItems.map((e) => MovieItem.fromJson(e)).toList();
      }).catchError((e) {
        debugPrint('KKPhim search error: $e');
        return <MovieItem>[];
      }),

      // Nguồn 2: VSMov
      _dio.get(vsMovUrl).then<List<MovieItem>>((res) {
        if (res.statusCode == 200 && res.data != null) {
          final items = res.data['items'] as List? ?? [];
          return items.map((e) => MovieItem.fromJson(e)).toList();
        }
        return <MovieItem>[];
      }).catchError((e) {
        debugPrint('VSMov search error: $e');
        return <MovieItem>[];
      }),
    ]);

    final kkPhimMovies = results[0];
    final vsMovMovies = results[1];

    // Gộp kết quả và khử trùng lặp (Deduplicate) theo slug hoặc tên
    final merged = <MovieItem>[];
    final seenSlugs = <String>{};
    final seenNames = <String>{};

    for (final m in kkPhimMovies) {
      if (seenSlugs.add(m.slug)) {
        seenNames.add(m.name.toLowerCase().trim());
        merged.add(m);
      }
    }

    for (final m in vsMovMovies) {
      final nameKey = m.name.toLowerCase().trim();
      if (!seenSlugs.contains(m.slug) && !seenNames.contains(nameKey)) {
        seenSlugs.add(m.slug);
        seenNames.add(nameKey);
        merged.add(m);
      }
    }

    // Nếu cả KKPhim và VSMov đều không có kết quả, fallback sang NguonC
    if (merged.isEmpty) {
      try {
        final nguonCUrl = '$nguonCApi/films/search?keyword=$encoded&page=$page';
        final res = await _dio.get(nguonCUrl);
        if (res.statusCode == 200 && res.data != null) {
          final items = res.data['items'] as List? ?? [];
          if (items.isNotEmpty) {
            return items.map((e) => MovieItem.fromJson(e)).toList();
          }
        }
      } catch (e) {
        debugPrint('NguonC search fallback error: $e');
      }
    }

    return merged;
  }

  // 5. Chi tiết phim đa nguồn (KKPhim chính + NguonC + VSMov) tích hợp TMDB ngay từ đầu
  Future<MovieDetail> getMovieDetail(String slug) async {
    final primaryUrl = '$primaryApi/phim/$slug';
    MovieDetail detail;

    try {
      final data = await _fetchWithCache(primaryUrl, maxAge: const Duration(minutes: 20));
      detail = MovieDetail.fromJson(data);
    } catch (e) {
      debugPrint('Primary API error for detail: $e. Trying NguonC fallback...');
      try {
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
            detail = MovieDetail.fromJson(movieData, explicitEpisodes: servers);
          } else {
            throw Exception('Empty movie data on NguonC');
          }
        } else {
          throw Exception('NguonC HTTP ${res.statusCode}');
        }
      } catch (nguonCErr) {
        debugPrint('NguonC fallback error: $nguonCErr. Trying VSMov fallback...');
        // Fallback 2: VSMov
        final vsMovUrl = '$vsMovApi/phim/$slug';
        final vsRes = await _dio.get(vsMovUrl);
        if (vsRes.statusCode == 200 && vsRes.data != null && vsRes.data['movie'] != null) {
          final movieData = vsRes.data['movie'];
          final servers = <EpisodeServer>[];
          if (vsRes.data['episodes'] is List) {
            for (final s in vsRes.data['episodes']) {
              if (s is Map<String, dynamic>) {
                servers.add(EpisodeServer.fromJson(s));
              }
            }
          }
          detail = MovieDetail.fromJson(movieData, explicitEpisodes: servers);
        } else {
          rethrow;
        }
      }
    }

    // Tự động gộp thêm Server phát từ VSMov (Triple-Source Streaming)
    try {
      final vsMovUrl = '$vsMovApi/phim/$slug';
      final vsData = await _fetchWithCache(vsMovUrl, maxAge: const Duration(minutes: 20))
          .timeout(const Duration(milliseconds: 1500));
      if (vsData != null && vsData['episodes'] is List) {
        final vsEpisodes = vsData['episodes'] as List;
        final newServers = List<EpisodeServer>.from(detail.episodes);
        for (final s in vsEpisodes) {
          if (s is Map<String, dynamic>) {
            final server = EpisodeServer.fromJson(s);
            if (server.serverData.isNotEmpty) {
              final serverTitle = server.serverName.contains('VSMov')
                  ? server.serverName
                  : 'VSMov - ${server.serverName}';
              newServers.add(EpisodeServer(
                serverName: serverTitle,
                serverData: server.serverData,
              ));
            }
          }
        }
        if (newServers.length > detail.episodes.length) {
          detail = detail.copyWithEpisodes(newServers);
        }
      }
    } catch (e) {
      debugPrint('VSMov server merge non-blocking: $e');
    }

    // Tích hợp TMDB đồng bộ ngay khi load:
    // Nếu có dữ liệu TMDB -> áp dụng ngay lập tức không bị delay/nhảy màn hình
    // Nếu timeout (sau 1.5s) hoặc lỗi mạng -> tự động fallback giữ nguyên dữ liệu gốc
    try {
      final tmdb = await TmdbService().enrichMovie(
        title: detail.name,
        originName: detail.originName,
        year: detail.year,
        knownActors: detail.actors,
        knownDirectors: detail.directors,
      ).timeout(const Duration(milliseconds: 1500));
      if (tmdb != null) {
        detail = detail.copyWithTmdb(tmdb);
      }
    } catch (e) {
      debugPrint('TMDB enrich timeout or error: $e. Fallback to KKPhim.');
    }

    return detail;
  }
}
