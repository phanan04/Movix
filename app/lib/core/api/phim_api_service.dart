import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../cache/cache_manager.dart';
import '../models/movie_model.dart';
import '../services/tmdb_service.dart';

// Top-level function for background isolate execution via compute()
List<MovieItem> _parseMovieItemList(List<dynamic> rawItems) {
  return rawItems.map((e) => MovieItem.fromJson(e as Map<String, dynamic>)).toList();
}

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

  // Helper to parse movie lists in background isolate via compute() for 60/120fps UI
  Future<List<MovieItem>> _parseWithIsolate(List<dynamic> rawItems) async {
    if (rawItems.isEmpty) return [];
    if (rawItems.length <= 6) {
      return _parseMovieItemList(rawItems);
    }
    return compute(_parseMovieItemList, rawItems);
  }

  // 1. Phim mới cập nhật
  Future<List<MovieItem>> getNewUpdates({int page = 1}) async {
    final url = '$primaryApi/danh-sach/phim-moi-cap-nhat?page=$page';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 5));
    final rawItems = data['items'] as List? ?? [];
    return _parseWithIsolate(rawItems);
  }

  // 2. Phim theo danh mục (phim-bo, phim-le, phim-chieu-rap, hoat-hinh, tv-shows)
  Future<List<MovieItem>> getMoviesByType(String type, {int page = 1, int limit = 20}) async {
    final url = '$primaryApi/v1/api/danh-sach/$type?page=$page&limit=$limit';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 15));
    final rawItems = data['data']?['items'] as List? ?? [];
    return _parseWithIsolate(rawItems);
  }

  // 3. Phim theo thể loại
  Future<List<MovieItem>> getMoviesByCategory(String categorySlug, {int page = 1, int limit = 20}) async {
    final url = '$primaryApi/v1/api/the-loai/$categorySlug?page=$page&limit=$limit';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 15));
    final rawItems = data['data']?['items'] as List? ?? [];
    return _parseWithIsolate(rawItems);
  }

  // 3b. Phim theo quốc gia
  Future<List<MovieItem>> getMoviesByCountry(String countrySlug, {int page = 1, int limit = 24}) async {
    final url = '$primaryApi/v1/api/quoc-gia/$countrySlug?page=$page&limit=$limit';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 15));
    final rawItems = data['data']?['items'] as List? ?? [];
    return _parseWithIsolate(rawItems);
  }

  // 3c. Phim theo năm phát hành
  Future<List<MovieItem>> getMoviesByYear(int year, {int page = 1, int limit = 24}) async {
    final url = '$primaryApi/v1/api/nam/$year?page=$page&limit=$limit';
    final data = await _fetchWithCache(url, maxAge: const Duration(minutes: 15));
    final rawItems = data['data']?['items'] as List? ?? [];
    return _parseWithIsolate(rawItems);
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
    return _parseWithIsolate(rawItems);
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
      // Nguồn 1: KKPhim (Xử lý đa luồng qua Isolate)
      _fetchWithCache(kkPhimUrl, maxAge: const Duration(minutes: 5))
          .then<List<MovieItem>>((data) {
        final rawItems = data?['data']?['items'] as List? ?? [];
        return _parseWithIsolate(rawItems);
      }).catchError((e) {
        debugPrint('KKPhim search error: $e');
        return <MovieItem>[];
      }),

      // Nguồn 2: VSMov (Xử lý đa luồng qua Isolate)
      _dio.get(vsMovUrl).then<List<MovieItem>>((res) {
        if (res.statusCode == 200 && res.data != null) {
          final items = res.data['items'] as List? ?? [];
          return _parseWithIsolate(items);
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
        try {
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
            throw Exception('Empty movie data on VSMov');
          }
        } catch (_) {
          // Fallback 3: Tìm kiếm phim theo tên nếu slug trực tiếp không khớp
          try {
            final queryTitle = slug.replaceAll('tmdb-', '').replaceAll('-', ' ').trim();
            final searchResults = await searchMovies(queryTitle, limit: 1);
            if (searchResults.isNotEmpty && searchResults.first.slug != slug) {
              return await getMovieDetail(searchResults.first.slug);
            }
          } catch (_) {}
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

  // 5. Phim tương tự theo TMDb Recommendations kết hợp Fallback
  Future<List<MovieItem>> getSimilarMovies(MovieDetail movie) async {
    final results = <MovieItem>[];
    final seenSlugs = <String>{movie.slug};

    int? tmdbId = movie.tmdbId;
    String? mediaType = movie.tmdbMediaType;

    // Nếu movie chưa có tmdbId, tra cứu nhanh qua TmdbService
    if (tmdbId == null || mediaType == null) {
      try {
        final tmdb = await TmdbService().enrichMovie(
          title: movie.name,
          originName: movie.originName,
          year: movie.year > 0 ? movie.year : null,
          knownActors: movie.actors,
          knownDirectors: movie.directors,
        );
        if (tmdb != null) {
          tmdbId = tmdb.id;
          mediaType = tmdb.mediaType;
        }
      } catch (e) {
        debugPrint('TMDB enrich in getSimilarMovies error: $e');
      }
    }

    // 1. Nếu có TMDb ID, truy vấn TMDb Recommendations
    if (tmdbId != null && mediaType != null) {
      final recTitles = await TmdbService().getRecommendedTitles(
        tmdbId: tmdbId,
        mediaType: mediaType,
      );

      if (recTitles.isNotEmpty) {
        // Tìm kiếm song song trên kho phim Movix (tối đa 12 tựa phim gợi ý từ TMDb)
        final searchFutures = recTitles.take(12).map((title) async {
          try {
            final searchRes = await searchMovies(title, limit: 1);
            return searchRes.isNotEmpty ? searchRes.first : null;
          } catch (_) {
            return null;
          }
        });

        final matchedList = await Future.wait(searchFutures);
        for (final m in matchedList) {
          if (m != null && !seenSlugs.contains(m.slug)) {
            seenSlugs.add(m.slug);
            results.add(m);
          }
        }
      }
    }

    // 2. Dự phòng thông minh (Fallback) nếu TMDb trả về ít hơn 8 phim
    if (results.length < 8) {
      final categorySlug = movie.categories.isNotEmpty ? movie.categories.first.slug : 'hanh-dong';
      try {
        final fallbackMovies = await getMoviesByCategory(categorySlug, page: 1, limit: 16);
        for (final fb in fallbackMovies) {
          if (!seenSlugs.contains(fb.slug)) {
            seenSlugs.add(fb.slug);
            results.add(fb);
          }
        }
      } catch (e) {
        debugPrint('Fallback getMoviesByCategory error: $e');
      }
    }

    return results;
  }
}
