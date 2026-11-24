import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class TmdbCast {
  final int id;
  final String name;
  final String character;
  final String? profileUrl;

  const TmdbCast({
    required this.id,
    required this.name,
    required this.character,
    this.profileUrl,
  });

  factory TmdbCast.fromJson(Map<String, dynamic> json) {
    final profilePath = json['profile_path']?.toString();
    return TmdbCast(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name']?.toString() ?? '',
      character: json['character']?.toString() ?? '',
      profileUrl: (profilePath != null && profilePath.isNotEmpty)
          ? 'https://image.tmdb.org/t/p/w185$profilePath'
          : null,
    );
  }
}

class TmdbMovieData {
  final int id;
  final String mediaType; // 'movie' or 'tv'
  final String? backdropUrl;
  final String? posterUrl;
  final double voteAverage;
  final int voteCount;
  final List<TmdbCast> cast;
  final String? trailerYoutubeKey;
  final List<String> genres;
  final int? runtimeMinutes;
  final String? overviewVi;

  const TmdbMovieData({
    required this.id,
    required this.mediaType,
    this.backdropUrl,
    this.posterUrl,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.cast = const [],
    this.trailerYoutubeKey,
    this.genres = const [],
    this.runtimeMinutes,
    this.overviewVi,
  });

  String get ratingDisplay => voteAverage > 0 ? voteAverage.toStringAsFixed(1) : '';
}

class TmdbService {
  static final TmdbService _instance = TmdbService._internal();
  factory TmdbService() => _instance;

  static const String apiKey = 'bcaca9f40f8f95da6489ab1de3576626';
  static const String bearerToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJiY2FjYTlmNDBmOGY5NWRhNjQ4OWFiMWRlMzU3NjYyNiIsIm5iZiI6MTc5NTMxOTM2MC4wNjMsInN1YiI6IjZiMDI2NjQwNGEyNjQ5OGQ1OTE0NTcwNSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.KpDG-jU8FQBw1ibqpyCKY_x_Y1zWLEEbPlzwLeHfOa0';
  static const String baseUrl = 'https://api.themoviedb.org/3';

  late final Dio _dio;
  final Map<String, TmdbMovieData> _memoryCache = {};

  TmdbService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 6),
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Chuẩn hóa chuỗi văn bản (bỏ dấu tiếng Việt, ký tự đặc biệt) để so khớp chính xác
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

  /// Làm sạch tên phim để tìm kiếm chính xác trên TMDB
  String _sanitizeTitle(String raw) {
    var cleaned = raw.split('/').first;
    cleaned = cleaned.replaceAll(RegExp(r'\([^)]*\)'), ''); // bỏ (2024), (Thuyết minh)
    cleaned = cleaned.replaceAll(RegExp(r'\[[^\]]*\]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'Tập\s+\d+', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'Phần\s+\d+', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'Season\s+\d+', caseSensitive: false), '');
    return cleaned.trim();
  }

  /// Tra cứu bổ sung thông tin từ TMDB (Backdrop 4K, Poster HD, Cast có ảnh, Rating thật, Trailer)
  /// Có cơ chế Cross-Validation nghiêm ngặt đối chiếu diễn viên/đạo diễn để ngăn chặn việc bắt nhầm phim
  Future<TmdbMovieData?> enrichMovie({
    required String title,
    String? originName,
    int? year,
    List<String> knownActors = const [],
    List<String> knownDirectors = const [],
  }) async {
    final cacheKey = '${title}_${originName ?? ''}_${year ?? ''}'.toLowerCase();
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    try {
      final queriesToTry = <String>[];
      final cleanTitle = _sanitizeTitle(title);
      final cleanOrigin = originName != null ? _sanitizeTitle(originName) : '';

      // 1. Ưu tiên tìm theo tên chính trước
      if (cleanTitle.isNotEmpty) {
        queriesToTry.add(cleanTitle);
      }

      // 2. Tên gốc originName chỉ tìm khi có từ 2 từ trở lên hoặc khác biệt rõ rệt
      // Tránh các từ đơn lẻ như "Hamlet", "Home", "Run", "Love" bị dịch bừa từ tên tiếng Việt
      if (cleanOrigin.isNotEmpty && cleanOrigin != cleanTitle) {
        final originWords = cleanOrigin.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (originWords.length > 1 || cleanOrigin.length >= 8) {
          queriesToTry.add(cleanOrigin);
        } else if (queriesToTry.isEmpty) {
          // Chỉ thêm từ đơn nếu chưa có query nào
          queriesToTry.add(cleanOrigin);
        }
      }

      Map<String, dynamic>? bestResult;
      String mediaType = 'movie';

      for (final query in queriesToTry) {
        if (query.isEmpty) continue;
        final res = await _dio.get(
          '/search/multi',
          queryParameters: {
            'query': query,
            'language': 'vi-VN',
            'include_adult': false,
          },
        );

        if (res.statusCode == 200 && res.data != null) {
          final results = res.data['results'] as List? ?? [];
          final mediaList = results.where((e) => e['media_type'] == 'movie' || e['media_type'] == 'tv').toList();

          if (mediaList.isNotEmpty) {
            // Ưu tiên trùng năm phát hành nếu có
            if (year != null && year > 0) {
              final matchedYear = mediaList.firstWhere(
                (item) {
                  final date = (item['release_date'] ?? item['first_air_date'])?.toString() ?? '';
                  return date.startsWith(year.toString());
                },
                orElse: () => mediaList.first,
              );
              bestResult = matchedYear;
            } else {
              bestResult = mediaList.first;
            }
            mediaType = bestResult?['media_type']?.toString() ?? 'movie';
            break;
          }
        }
      }

      if (bestResult == null) {
        return null;
      }

      final tmdbId = bestResult['id'] as int;

      // Truy vấn chi tiết kèm credits và video trailers
      final detailRes = await _dio.get(
        '/$mediaType/$tmdbId',
        queryParameters: {
          'append_to_response': 'credits,videos',
          'language': 'vi-VN',
        },
      );

      if (detailRes.statusCode != 200 || detailRes.data == null) {
        return null;
      }

      final data = detailRes.data;

      // ==========================================
      // GUARDRAIL: CROSS-VALIDATION ĐỐI CHIẾU DIỄN VIÊN / TIÊU ĐỀ
      // ==========================================
      final rawCast = data['credits']?['cast'] as List? ?? [];
      final rawCrew = data['credits']?['crew'] as List? ?? [];

      final validKnownActors = knownActors
          .map(_normalizeText)
          .where((s) => s.isNotEmpty && s.length > 2)
          .toList();
      final validKnownDirectors = knownDirectors
          .map(_normalizeText)
          .where((s) => s.isNotEmpty && s.length > 2)
          .toList();

      if (validKnownActors.length >= 2) {
        final tmdbPeople = <String>[];
        for (final c in rawCast.take(15)) {
          if (c is Map && c['name'] != null) {
            tmdbPeople.add(_normalizeText(c['name'].toString()));
          }
        }
        for (final c in rawCrew.take(10)) {
          if (c is Map && c['name'] != null && (c['job'] == 'Director' || c['department'] == 'Directing')) {
            tmdbPeople.add(_normalizeText(c['name'].toString()));
          }
        }

        bool hasPersonMatch = false;
        for (final ka in validKnownActors) {
          for (final tp in tmdbPeople) {
            if (ka == tp || (ka.length > 4 && tp.contains(ka)) || (tp.length > 4 && ka.contains(tp))) {
              hasPersonMatch = true;
              break;
            }
          }
          if (hasPersonMatch) break;
        }

        if (!hasPersonMatch) {
          for (final kd in validKnownDirectors) {
            for (final tp in tmdbPeople) {
              if (kd == tp || (kd.length > 4 && tp.contains(kd)) || (tp.length > 4 && kd.contains(tp))) {
                hasPersonMatch = true;
                break;
              }
            }
            if (hasPersonMatch) break;
          }
        }

        // Nếu KHÔNG có bất kỳ diễn viên hoặc đạo diễn nào trùng khớp
        if (!hasPersonMatch) {
          final tmdbTitle = _normalizeText(data['title']?.toString() ?? data['name']?.toString() ?? '');
          final tmdbOrigTitle = _normalizeText(data['original_title']?.toString() ?? data['original_name']?.toString() ?? '');
          final normTitle = _normalizeText(title);
          final normOrig = originName != null ? _normalizeText(originName) : '';

          final titleMatches = normTitle.isNotEmpty && (tmdbTitle == normTitle || tmdbOrigTitle == normTitle);
          final origMatches = normOrig.isNotEmpty &&
              normOrig.split(' ').length > 1 &&
              (tmdbTitle == normOrig || tmdbOrigTitle == normOrig);

          if (!titleMatches && !origMatches) {
            debugPrint('TMDB Match REJECTED for "$title": 0/${validKnownActors.length} actors matched. TMDB: "$tmdbTitle" ($tmdbId)');
            return null;
          }
        }
      }

      // Backdrop HD (w1280)
      final rawBackdrop = data['backdrop_path']?.toString();
      final backdropUrl = (rawBackdrop != null && rawBackdrop.isNotEmpty)
          ? 'https://image.tmdb.org/t/p/w1280$rawBackdrop'
          : null;

      // Poster HD (w780)
      final rawPoster = data['poster_path']?.toString();
      final posterUrl = (rawPoster != null && rawPoster.isNotEmpty)
          ? 'https://image.tmdb.org/t/p/w780$rawPoster'
          : null;

      final voteAverage = (data['vote_average'] is num) ? (data['vote_average'] as num).toDouble() : 0.0;
      final voteCount = (data['vote_count'] is int) ? data['vote_count'] as int : 0;

      // Diễn viên (Top 12)
      final castList = <TmdbCast>[];
      for (final c in rawCast.take(12)) {
        if (c is Map<String, dynamic>) {
          castList.add(TmdbCast.fromJson(c));
        }
      }

      // Trailer YouTube chính thức
      final rawVideos = data['videos']?['results'] as List? ?? [];
      String? youtubeTrailerKey;
      for (final v in rawVideos) {
        if (v['site'] == 'YouTube' && (v['type'] == 'Trailer' || v['type'] == 'Teaser')) {
          youtubeTrailerKey = v['key']?.toString();
          if (v['type'] == 'Trailer') break; // Ưu tiên Trailer
        }
      }

      final rawGenres = data['genres'] as List? ?? [];
      final genres = rawGenres.map((g) => g['name']?.toString() ?? '').where((g) => g.isNotEmpty).toList();

      final runtime = (data['runtime'] is int)
          ? data['runtime'] as int
          : ((data['episode_run_time'] is List && (data['episode_run_time'] as List).isNotEmpty)
              ? (data['episode_run_time'][0] as int?)
              : null);

      final enriched = TmdbMovieData(
        id: tmdbId,
        mediaType: mediaType,
        backdropUrl: backdropUrl,
        posterUrl: posterUrl,
        voteAverage: voteAverage,
        voteCount: voteCount,
        cast: castList,
        trailerYoutubeKey: youtubeTrailerKey,
        genres: genres,
        runtimeMinutes: runtime,
        overviewVi: data['overview']?.toString(),
      );

      _memoryCache[cacheKey] = enriched;
      return enriched;
    } catch (e) {
      debugPrint('TMDB Enrich error for $title: $e');
      return null;
    }
  }
}
