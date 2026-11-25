import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../cache/cache_manager.dart';
import '../models/movie_model.dart';
import '../services/tmdb_service.dart';

class MovieDetailRequest {
  final String slug;
  final int? tmdbId;
  final String? tmdbMediaType;
  final MovieItem? previewMovie;

  const MovieDetailRequest({
    required this.slug,
    this.tmdbId,
    this.tmdbMediaType,
    this.previewMovie,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieDetailRequest &&
          runtimeType == other.runtimeType &&
          slug == other.slug &&
          tmdbId == other.tmdbId &&
          tmdbMediaType == other.tmdbMediaType;

  @override
  int get hashCode => Object.hash(slug, tmdbId, tmdbMediaType);
}

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
        sendTimeout: kIsWeb ? null : const Duration(seconds: 6),
        headers: {
          'Accept': 'application/json',
          if (!kIsWeb) 'User-Agent': 'MovixFlutter/1.0',
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

  // Helper to parse movie lists cleanly without isolate overhead on Web
  Future<List<MovieItem>> _parseWithIsolate(List<dynamic> rawItems) async {
    if (rawItems.isEmpty) return [];
    if (kIsWeb || rawItems.length <= 12) {
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

      // Nguồn 2: VSMov (bỏ qua trên Web vì VSMov không hỗ trợ CORS trình duyệt)
      if (kIsWeb)
        Future.value(<MovieItem>[])
      else
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

  String _normalizeText(String raw) {
    var s = raw.toLowerCase().trim();
    const withDia = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    for (int i = 0; i < withDia.length; i++) {
      s = s.replaceAll(withDia[i], withoutDia[i]);
    }
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Chọn kết quả khớp chính xác nhất theo tmdbId (ưu tiên tuyệt đối) hoặc tiêu đề + năm
  MovieItem? _pickBestPlayableMatch(
    List<MovieItem> candidates, {
    int? tmdbId,
    String? tmdbMediaType,
    String? title,
    String? originName,
    int? year,
  }) {
    if (candidates.isEmpty) return null;

    if (tmdbId != null && tmdbId > 0) {
      // 1. Khớp chính xác tmdbId & mediaType
      for (final c in candidates) {
        if (c.tmdbId == tmdbId) {
          if (tmdbMediaType == null || c.tmdbMediaType == null || c.tmdbMediaType == tmdbMediaType) {
            return c;
          }
        }
      }
      // 2. Khớp tmdbId (bỏ qua mediaType nếu nguồn không ghi rõ)
      for (final c in candidates) {
        if (c.tmdbId == tmdbId) return c;
      }
    }

    // 3. Không bao giờ lấy phim có tmdbId KHÁC với tmdbId cần tìm
    final normTitle = title != null ? _normalizeText(title) : '';
    final normOrig = originName != null ? _normalizeText(originName) : '';

    for (final c in candidates) {
      if (tmdbId != null && c.tmdbId != null && c.tmdbId != tmdbId) {
        continue;
      }
      final cName = _normalizeText(c.name);
      final cOrig = _normalizeText(c.originName);
      final nameMatches = (normTitle.isNotEmpty && (cName == normTitle || cOrig == normTitle)) ||
          (normOrig.isNotEmpty && (cOrig == normOrig || cName == normOrig));
      if (!nameMatches) continue;

      if (year != null && year > 0 && c.year > 0 && (c.year - year).abs() > 1) {
        continue;
      }
      return c;
    }

    return null;
  }

  /// Tải trực tiếp chi tiết phim theo slug (KKPhim chính; nếu lỗi thì chạy song song NguonC + VSMov)
  Future<MovieDetail> _fetchDirectBySlug(String slug) async {
    final primaryUrl = '$primaryApi/phim/$slug';
    try {
      final data = await _fetchWithCache(primaryUrl, maxAge: const Duration(minutes: 20));
      final detail = MovieDetail.fromJson(data);
      if (detail.name.isNotEmpty) return detail;
    } catch (e) {
      debugPrint('Primary API detail miss for "$slug": $e. Trying NguonC & VSMov in parallel...');
    }

    Future<MovieDetail?> tryNguonC() async {
      try {
        final res = await _dio.get('$nguonCApi/film/$slug').timeout(const Duration(seconds: 4));
        if (res.statusCode == 200 && res.data != null) {
          final movieData = res.data['movie'];
          if (movieData != null) {
            final servers = <EpisodeServer>[];
            if (movieData['episodes'] is List) {
              for (final s in movieData['episodes']) {
                if (s is Map<String, dynamic>) {
                  servers.add(EpisodeServer.fromJson(s));
                }
              }
            }
            final detail = MovieDetail.fromJson(movieData, explicitEpisodes: servers);
            if (detail.name.isNotEmpty) return detail;
          }
        }
      } catch (_) {}
      return null;
    }

    Future<MovieDetail?> tryVsMov() async {
      if (kIsWeb) return null;
      try {
        final vsRes = await _dio.get('$vsMovApi/phim/$slug').timeout(const Duration(seconds: 4));
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
          final detail = MovieDetail.fromJson(movieData, explicitEpisodes: servers);
          if (detail.name.isNotEmpty) return detail;
        }
      } catch (_) {}
      return null;
    }

    final fallbackResults = await Future.wait([tryNguonC(), tryVsMov()]);
    for (final res in fallbackResults) {
      if (res != null) return res;
    }

    throw Exception('Không tìm thấy thông tin phim ($slug)');
  }

  /// Gộp thêm Server phát từ VSMov (không chặn UI nếu chậm, bỏ qua trên Web vì không có CORS)
  Future<MovieDetail> _mergeVsMovEpisodes(MovieDetail detail) async {
    if (kIsWeb || detail.slug.isEmpty) return detail;
    try {
      final vsMovUrl = '$vsMovApi/phim/${detail.slug}';
      final vsData = await _fetchWithCache(vsMovUrl, maxAge: const Duration(minutes: 20))
          .timeout(const Duration(milliseconds: 1800));
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
          return detail.copyWithEpisodes(newServers);
        }
      }
    } catch (e) {
      debugPrint('VSMov server merge non-blocking: $e');
    }
    return detail;
  }

  // 5. Chi tiết phim đa nguồn tối ưu song song, khớp chính xác tuyệt đối theo tmdbId
  Future<MovieDetail> getMovieDetail(
    String slug, {
    int? tmdbId,
    String? tmdbMediaType,
    MovieItem? previewMovie,
  }) async {
    // =========================================================================
    // TRƯỜNG HỢP A: Phim mở từ nguồn TMDb (có sẵn tmdbId chuẩn xác)
    // =========================================================================
    if (tmdbId != null && tmdbId > 0) {
      final tmdbFuture = TmdbService()
          .getDetailById(tmdbId, tmdbMediaType ?? 'movie')
          .timeout(const Duration(seconds: 4), onTimeout: () => null);

      Future<MovieDetail?> resolveStreamForTmdb(TmdbMovieData? tmdbData) async {
        // 1. Thử lấy trực tiếp theo slug nếu slug có vẻ hợp lệ và khớp tmdbId
        if (!slug.startsWith('tmdb-')) {
          try {
            final direct = await _fetchDirectBySlug(slug).timeout(const Duration(milliseconds: 2500));
            if (direct.tmdbId == tmdbId) {
              return direct;
            }
            if (direct.tmdbId == null) {
              final refTitle = tmdbData?.title ?? previewMovie?.name ?? '';
              final refOrig = tmdbData?.originalTitle ?? previewMovie?.originName ?? '';
              final refYear = tmdbData?.year ?? previewMovie?.year;
              final normDName = _normalizeText(direct.name);
              final normDOrig = _normalizeText(direct.originName);
              final titleOk = (refTitle.isNotEmpty && (normDName == _normalizeText(refTitle) || normDOrig == _normalizeText(refTitle))) ||
                  (refOrig.isNotEmpty && (normDOrig == _normalizeText(refOrig) || normDName == _normalizeText(refOrig)));
              final yearOk = refYear == null || refYear <= 0 || direct.year <= 0 || (direct.year - refYear).abs() <= 1;
              if (titleOk && yearOk) return direct;
            }
            debugPrint('Slug "$slug" on KKPhim is tmdbId=${direct.tmdbId}, expected $tmdbId. Searching exact match...');
          } catch (_) {}
        }

        // 2. Tìm kiếm chính xác theo tên gốc / tên tiếng Việt trên KKPhim + VSMov và lọc theo tmdbId
        final searchQueries = <String>[];
        final origQ = (tmdbData?.originalTitle ?? previewMovie?.originName ?? '').trim();
        final viQ = (tmdbData?.title ?? previewMovie?.name ?? '').trim();
        if (origQ.isNotEmpty) searchQueries.add(origQ);
        if (viQ.isNotEmpty && viQ.toLowerCase() != origQ.toLowerCase()) searchQueries.add(viQ);
        if (searchQueries.isEmpty && slug.isNotEmpty) {
          searchQueries.add(slug.replaceAll('tmdb-', '').replaceAll('-', ' ').trim());
        }

        for (final q in searchQueries) {
          try {
            final candidates = await searchMovies(q, limit: 12).timeout(const Duration(seconds: 3));
            final matched = _pickBestPlayableMatch(
              candidates,
              tmdbId: tmdbId,
              tmdbMediaType: tmdbMediaType,
              title: viQ,
              originName: origQ,
              year: tmdbData?.year ?? previewMovie?.year,
            );
            if (matched != null && matched.slug.isNotEmpty) {
              return await _fetchDirectBySlug(matched.slug).timeout(const Duration(seconds: 3));
            }
          } catch (_) {}
        }
        return null;
      }

      // Chạy song song tra cứu TMDb và tìm nguồn phát
      final tmdbData = await tmdbFuture;
      final playable = await resolveStreamForTmdb(tmdbData)
          .timeout(const Duration(seconds: 5), onTimeout: () => null);

      if (playable != null) {
        var finalDetail = await _mergeVsMovEpisodes(playable);
        if (tmdbData != null) {
          finalDetail = finalDetail.copyWithTmdb(tmdbData);
        }
        return finalDetail;
      }

      // Nếu không có bản chiếu trên KKPhim/VSMov -> vẫn hiển thị đầy đủ & chuẩn xác thông tin TMDb
      if (tmdbData != null) {
        return MovieDetail.fromTmdb(tmdbData, preview: previewMovie, fallbackSlug: slug);
      }
      if (previewMovie != null) {
        return MovieDetail(
          id: previewMovie.id,
          name: previewMovie.name,
          originName: previewMovie.originName,
          slug: previewMovie.slug,
          type: previewMovie.tmdbMediaType == 'tv' ? 'series' : 'single',
          thumbUrl: previewMovie.thumbUrl,
          posterUrl: previewMovie.posterUrl,
          time: previewMovie.time,
          episodeCurrent: previewMovie.episodeCurrent,
          episodeTotal: '',
          quality: previewMovie.quality,
          lang: previewMovie.lang,
          year: previewMovie.year,
          content: 'Thông tin phim từ TMDb. Hiện chưa có nguồn phát trực tuyến.',
          actors: const [],
          directors: const [],
          categories: const [],
          episodes: const [],
          tmdbId: previewMovie.tmdbId,
          tmdbMediaType: previewMovie.tmdbMediaType,
          tmdbVoteAverage: previewMovie.voteAverage,
        );
      }
      throw Exception('Không thể tải thông tin phim TMDb #$tmdbId');
    }

    // =========================================================================
    // TRƯỜNG HỢP B: Phim mở theo slug KKPhim / Tiếp tục xem / Danh sách lưu
    // =========================================================================
    MovieDetail detail;
    try {
      detail = await _fetchDirectBySlug(slug);
    } catch (e) {
      // Fallback tìm chính xác theo tên từ slug nếu slug cũ bị đổi (không đệ quy vô hạn)
      final queryTitle = slug.replaceAll('tmdb-', '').replaceAll('-', ' ').trim();
      final candidates = await searchMovies(queryTitle, limit: 8).timeout(
        const Duration(seconds: 3),
        onTimeout: () => <MovieItem>[],
      );
      final match = _pickBestPlayableMatch(candidates, title: queryTitle);
      if (match != null && match.slug.isNotEmpty && match.slug != slug) {
        detail = await _fetchDirectBySlug(match.slug);
      } else {
        rethrow;
      }
    }

    // Chạy SONG SONG việc gộp server VSMov và làm giàu dữ liệu TMDb (ưu tiên tmdbId của chính KKPhim)
    final parallelResults = await Future.wait([
      _mergeVsMovEpisodes(detail),
      TmdbService()
          .enrichMovie(
            title: detail.name,
            originName: detail.originName,
            year: detail.year > 0 ? detail.year : null,
            knownActors: detail.actors,
            knownDirectors: detail.directors,
            tmdbId: detail.tmdbId,
            mediaType: detail.tmdbMediaType,
            expectedType: detail.type,
          )
          .timeout(const Duration(milliseconds: 3500), onTimeout: () => null)
          .catchError((e) {
        debugPrint('TMDB enrich non-blocking error: $e');
        return null;
      }),
    ]);

    var enrichedDetail = parallelResults[0] as MovieDetail;
    final tmdb = parallelResults[1] as TmdbMovieData?;
    if (tmdb != null) {
      enrichedDetail = enrichedDetail.copyWithTmdb(tmdb);
    }

    return enrichedDetail;
  }

  // 6. Phim tương tự theo TMDb Recommendations (1 request trực tiếp, tốc độ cao & chuẩn xác) + Fallback
  Future<List<MovieItem>> getSimilarMovies(MovieDetail movie) async {
    final results = <MovieItem>[];
    final seenIds = <String>{movie.slug};
    if (movie.tmdbId != null) {
      seenIds.add('tmdb_${movie.tmdbId}');
    }

    int? tmdbId = movie.tmdbId;
    String? mediaType = movie.tmdbMediaType;

    if (tmdbId == null || mediaType == null) {
      try {
        final tmdb = await TmdbService().enrichMovie(
          title: movie.name,
          originName: movie.originName,
          year: movie.year > 0 ? movie.year : null,
          knownActors: movie.actors,
          knownDirectors: movie.directors,
          expectedType: movie.type,
        ).timeout(const Duration(seconds: 3), onTimeout: () => null);
        if (tmdb != null) {
          tmdbId = tmdb.id;
          mediaType = tmdb.mediaType;
        }
      } catch (e) {
        debugPrint('TMDB enrich in getSimilarMovies error: $e');
      }
    }

    // 1. Lấy trực tiếp MovieItem từ TMDb Recommendations (không spam search KKPhim, không khớp nhầm phim)
    if (tmdbId != null && mediaType != null) {
      final recs = await TmdbService().getRecommendations(
        tmdbId: tmdbId,
        mediaType: mediaType,
      );
      for (final m in recs) {
        final key = m.tmdbId != null ? 'tmdb_${m.tmdbId}' : m.slug;
        if (seenIds.add(key) && seenIds.add(m.slug)) {
          results.add(m);
        }
      }
    }

    // 2. Dự phòng thông minh nếu không có TMDb hoặc danh sách ít hơn 6 phim
    if (results.length < 6) {
      final categorySlug = (movie.categories.isNotEmpty && movie.categories.first.slug.contains('-'))
          ? movie.categories.first.slug
          : 'hanh-dong';
      try {
        final fallbackMovies = await getMoviesByCategory(categorySlug, page: 1, limit: 16);
        for (final fb in fallbackMovies) {
          final key = fb.tmdbId != null ? 'tmdb_${fb.tmdbId}' : fb.slug;
          if (seenIds.add(key) && seenIds.add(fb.slug)) {
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
