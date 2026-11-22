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
  Future<TmdbMovieData?> enrichMovie({
    required String title,
    String? originName,
    int? year,
  }) async {
    final cacheKey = '${title}_${originName ?? ''}_${year ?? ''}'.toLowerCase();
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    try {
      final queriesToTry = <String>[];
      if (originName != null && originName.trim().isNotEmpty && originName != title) {
        queriesToTry.add(_sanitizeTitle(originName));
      }
      queriesToTry.add(_sanitizeTitle(title));

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
      final rawCast = data['credits']?['cast'] as List? ?? [];
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
