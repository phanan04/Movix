import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/movie_model.dart';

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

class TmdbCompany {
  final int id;
  final String name;
  final String? logoUrl;

  const TmdbCompany({required this.id, required this.name, this.logoUrl});

  factory TmdbCompany.fromJson(Map<String, dynamic> json) {
    final logoPath = json['logo_path']?.toString();
    return TmdbCompany(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name']?.toString() ?? '',
      logoUrl: (logoPath != null && logoPath.isNotEmpty)
          ? 'https://image.tmdb.org/t/p/w185$logoPath'
          : null,
    );
  }
}

class TmdbCollectionPart {
  final int id;
  final String title;
  final String? posterUrl;
  final String? backdropUrl;
  final String? releaseDate;
  final double voteAverage;

  const TmdbCollectionPart({
    required this.id,
    required this.title,
    this.posterUrl,
    this.backdropUrl,
    this.releaseDate,
    this.voteAverage = 0.0,
  });

  factory TmdbCollectionPart.fromJson(Map<String, dynamic> json) {
    final poster = json['poster_path']?.toString();
    final backdrop = json['backdrop_path']?.toString();
    final vote = (json['vote_average'] is num) ? (json['vote_average'] as num).toDouble() : 0.0;
    return TmdbCollectionPart(
      id: json['id'] is int ? json['id'] : 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      posterUrl: (poster != null && poster.isNotEmpty) ? 'https://image.tmdb.org/t/p/w342$poster' : null,
      backdropUrl: (backdrop != null && backdrop.isNotEmpty) ? 'https://image.tmdb.org/t/p/w780$backdrop' : null,
      releaseDate: (json['release_date'] ?? json['first_air_date'])?.toString(),
      voteAverage: vote,
    );
  }
}

class TmdbCollection {
  final int id;
  final String name;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final List<TmdbCollectionPart> parts;

  const TmdbCollection({
    required this.id,
    required this.name,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    this.parts = const [],
  });

  factory TmdbCollection.fromJson(Map<String, dynamic> json) {
    final poster = json['poster_path']?.toString();
    final backdrop = json['backdrop_path']?.toString();
    final rawParts = json['parts'] as List? ?? [];
    final parts = rawParts.map((p) => TmdbCollectionPart.fromJson(p as Map<String, dynamic>)).toList();
    parts.sort((a, b) => (a.releaseDate ?? '').compareTo(b.releaseDate ?? ''));

    return TmdbCollection(
      id: json['id'] is int ? json['id'] : 0,
      name: json['name']?.toString() ?? '',
      overview: json['overview']?.toString(),
      posterUrl: (poster != null && poster.isNotEmpty) ? 'https://image.tmdb.org/t/p/w500$poster' : null,
      backdropUrl: (backdrop != null && backdrop.isNotEmpty) ? 'https://image.tmdb.org/t/p/w1280$backdrop' : null,
      parts: parts,
    );
  }
}

class TmdbReview {
  final String id;
  final String author;
  final double? rating;
  final String content;
  final String? avatarUrl;
  final String createdAt;

  const TmdbReview({
    required this.id,
    required this.author,
    this.rating,
    required this.content,
    this.avatarUrl,
    required this.createdAt,
  });

  factory TmdbReview.fromJson(Map<String, dynamic> json) {
    final authorDetails = json['author_details'] as Map<String, dynamic>?;
    final rawAvatar = authorDetails?['avatar_path']?.toString();
    String? avatar;
    if (rawAvatar != null && rawAvatar.isNotEmpty) {
      if (rawAvatar.startsWith('http://') || rawAvatar.startsWith('https://')) {
        avatar = rawAvatar;
      } else if (rawAvatar.startsWith('/http')) {
        avatar = rawAvatar.substring(1);
      } else {
        avatar = 'https://image.tmdb.org/t/p/w185$rawAvatar';
      }
    }

    final ratingNum = authorDetails?['rating'];
    final rating = (ratingNum is num) ? ratingNum.toDouble() : null;

    return TmdbReview(
      id: json['id']?.toString() ?? '',
      author: json['author']?.toString() ?? 'Khán giả quốc tế',
      rating: rating,
      content: json['content']?.toString() ?? '',
      avatarUrl: avatar,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class TmdbPersonCredit {
  final int id;
  final String title;
  final String? originalTitle;
  final String mediaType;
  final String? posterUrl;
  final String? character;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;

  const TmdbPersonCredit({
    required this.id,
    required this.title,
    this.originalTitle,
    required this.mediaType,
    this.posterUrl,
    this.character,
    this.releaseDate,
    this.voteAverage = 0.0,
    this.voteCount = 0,
  });

  factory TmdbPersonCredit.fromJson(Map<String, dynamic> json) {
    final poster = json['poster_path']?.toString();
    final vote = (json['vote_average'] is num) ? (json['vote_average'] as num).toDouble() : 0.0;
    return TmdbPersonCredit(
      id: json['id'] is int ? json['id'] : 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      originalTitle: json['original_title']?.toString() ?? json['original_name']?.toString(),
      mediaType: json['media_type']?.toString() ?? 'movie',
      posterUrl: (poster != null && poster.isNotEmpty) ? 'https://image.tmdb.org/t/p/w342$poster' : null,
      character: json['character']?.toString(),
      releaseDate: (json['release_date'] ?? json['first_air_date'])?.toString(),
      voteAverage: vote,
      voteCount: json['vote_count'] is int ? json['vote_count'] : 0,
    );
  }
}

class TmdbPersonDetails {
  final int id;
  final String name;
  final String biography;
  final String? birthday;
  final String? placeOfBirth;
  final String? profileUrl;
  final String? knownForDepartment;
  final List<TmdbPersonCredit> credits;

  const TmdbPersonDetails({
    required this.id,
    required this.name,
    this.biography = '',
    this.birthday,
    this.placeOfBirth,
    this.profileUrl,
    this.knownForDepartment,
    this.credits = const [],
  });
}

class TmdbMovieData {
  final int id;
  final String mediaType; // 'movie' or 'tv'
  final String? title;
  final String? originalTitle;
  final int? year;
  final String? releaseDate;
  final List<String> directors;
  final int? numberOfEpisodes;
  final String? backdropUrl;
  final String? posterUrl;
  final String? clearLogoUrl;
  final double voteAverage;
  final int voteCount;
  final List<TmdbCast> cast;
  final String? trailerYoutubeKey;
  final List<String> genres;
  final int? runtimeMinutes;
  final String? overviewVi;
  final int? collectionId;
  final String? collectionName;
  final String? collectionBackdrop;
  final List<TmdbCompany> networks;
  final List<TmdbCompany> productionCompanies;

  const TmdbMovieData({
    required this.id,
    required this.mediaType,
    this.title,
    this.originalTitle,
    this.year,
    this.releaseDate,
    this.directors = const [],
    this.numberOfEpisodes,
    this.backdropUrl,
    this.posterUrl,
    this.clearLogoUrl,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.cast = const [],
    this.trailerYoutubeKey,
    this.genres = const [],
    this.runtimeMinutes,
    this.overviewVi,
    this.collectionId,
    this.collectionName,
    this.collectionBackdrop,
    this.networks = const [],
    this.productionCompanies = const [],
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
  final Map<String, TmdbMovieData> _detailByIdCache = {};
  final Map<String, Future<TmdbMovieData?>> _inFlightDetail = {};
  final Map<String, ({List<MovieItem> items, DateTime ts})> _trendingCache = {};
  final Map<String, Future<List<MovieItem>>> _inFlightTrending = {};

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

  /// Tra cứu chi tiết TMDb trực tiếp theo ID & mediaType (1 HTTP call, có cache & dedup)
  Future<TmdbMovieData?> getDetailById(int tmdbId, String mediaType) async {
    if (tmdbId <= 0) return null;
    final cleanType = (mediaType == 'tv') ? 'tv' : 'movie';
    final cacheKey = 'id_${cleanType}_$tmdbId';

    if (_detailByIdCache.containsKey(cacheKey)) {
      return _detailByIdCache[cacheKey];
    }
    if (_inFlightDetail.containsKey(cacheKey)) {
      return await _inFlightDetail[cacheKey];
    }

    final future = () async {
      try {
        final detailRes = await _dio.get(
          '/$cleanType/$tmdbId',
          queryParameters: {
            'append_to_response': 'credits,videos,images',
            'include_image_language': 'vi,en,null',
            'language': 'vi-VN',
          },
        );
        if (detailRes.statusCode != 200 || detailRes.data == null) {
          return null;
        }
        final parsed = _parseTmdbDetail(detailRes.data as Map<String, dynamic>, tmdbId, cleanType);
        _detailByIdCache[cacheKey] = parsed;
        return parsed;
      } catch (e) {
        debugPrint('TMDb getDetailById($cleanType/$tmdbId) error: $e');
        return null;
      }
    }();

    _inFlightDetail[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inFlightDetail.remove(cacheKey);
    }
  }

  TmdbMovieData _parseTmdbDetail(Map<String, dynamic> data, int tmdbId, String mediaType) {
    final rawCast = data['credits']?['cast'] as List? ?? [];
    final rawCrew = data['credits']?['crew'] as List? ?? [];

    final rawBackdrop = data['backdrop_path']?.toString();
    final backdropUrl = (rawBackdrop != null && rawBackdrop.isNotEmpty)
        ? 'https://image.tmdb.org/t/p/w1280$rawBackdrop'
        : null;

    final rawPoster = data['poster_path']?.toString();
    final posterUrl = (rawPoster != null && rawPoster.isNotEmpty)
        ? 'https://image.tmdb.org/t/p/w780$rawPoster'
        : null;

    final voteAverage = (data['vote_average'] is num) ? (data['vote_average'] as num).toDouble() : 0.0;
    final voteCount = (data['vote_count'] is int) ? data['vote_count'] as int : 0;

    final castList = <TmdbCast>[];
    for (final c in rawCast.take(12)) {
      if (c is Map<String, dynamic>) {
        castList.add(TmdbCast.fromJson(c));
      }
    }

    final directors = <String>[];
    for (final c in rawCrew) {
      if (c is Map && c['job'] == 'Director' && c['name'] != null) {
        final dName = c['name'].toString().trim();
        if (dName.isNotEmpty && !directors.contains(dName)) {
          directors.add(dName);
        }
      }
    }

    final rawVideos = data['videos']?['results'] as List? ?? [];
    String? youtubeTrailerKey;
    for (final v in rawVideos) {
      if (v['site'] == 'YouTube' && (v['type'] == 'Trailer' || v['type'] == 'Teaser')) {
        youtubeTrailerKey = v['key']?.toString();
        if (v['type'] == 'Trailer') break;
      }
    }

    final rawGenres = data['genres'] as List? ?? [];
    final genres = rawGenres.map((g) => g['name']?.toString() ?? '').where((g) => g.isNotEmpty).toList();

    final runtime = (data['runtime'] is int)
        ? data['runtime'] as int
        : ((data['episode_run_time'] is List && (data['episode_run_time'] as List).isNotEmpty)
            ? (data['episode_run_time'][0] as int?)
            : null);

    final rawLogos = data['images']?['logos'] as List? ?? [];
    String? clearLogoUrl;
    if (rawLogos.isNotEmpty) {
      final pngLogo = rawLogos.firstWhere(
        (l) => l['file_path']?.toString().toLowerCase().endsWith('.png') ?? false,
        orElse: () => rawLogos.first,
      );
      final filePath = pngLogo['file_path']?.toString();
      if (filePath != null && filePath.isNotEmpty) {
        clearLogoUrl = 'https://image.tmdb.org/t/p/w500$filePath';
      }
    }

    final collectionObj = data['belongs_to_collection'] as Map<String, dynamic>?;
    final collectionId = collectionObj?['id'] as int?;
    final collectionName = collectionObj?['name']?.toString();
    final collectionBackdrop = collectionObj?['backdrop_path']?.toString() != null
        ? 'https://image.tmdb.org/t/p/w1280${collectionObj!['backdrop_path']}'
        : null;

    final rawNetworks = data['networks'] as List? ?? [];
    final networks = rawNetworks
        .map((n) => TmdbCompany.fromJson(n as Map<String, dynamic>))
        .toList();

    final rawProdCompanies = data['production_companies'] as List? ?? [];
    final productionCompanies = rawProdCompanies
        .map((c) => TmdbCompany.fromJson(c as Map<String, dynamic>))
        .toList();

    final releaseDate = (data['release_date'] ?? data['first_air_date'])?.toString() ?? '';
    final year = int.tryParse(releaseDate.split('-').first);
    final numEpisodes = data['number_of_episodes'] is int ? data['number_of_episodes'] as int : null;

    return TmdbMovieData(
      id: tmdbId,
      mediaType: mediaType,
      title: data['title']?.toString() ?? data['name']?.toString(),
      originalTitle: data['original_title']?.toString() ?? data['original_name']?.toString(),
      year: year,
      releaseDate: releaseDate,
      directors: directors,
      numberOfEpisodes: numEpisodes,
      backdropUrl: backdropUrl,
      posterUrl: posterUrl,
      clearLogoUrl: clearLogoUrl,
      voteAverage: voteAverage,
      voteCount: voteCount,
      cast: castList,
      trailerYoutubeKey: youtubeTrailerKey,
      genres: genres,
      runtimeMinutes: runtime,
      overviewVi: data['overview']?.toString(),
      collectionId: collectionId,
      collectionName: collectionName,
      collectionBackdrop: collectionBackdrop,
      networks: networks,
      productionCompanies: productionCompanies,
    );
  }

  /// Kiểm tra chéo nghiêm ngặt giữa dữ liệu nguồn (KKPhim) và ứng viên TMDb
  bool _passesCrossValidation(
    TmdbMovieData candidate, {
    required String title,
    String? originName,
    int? year,
    List<String> knownActors = const [],
    List<String> knownDirectors = const [],
  }) {
    final validKnownActors = knownActors
        .map(_normalizeText)
        .where((s) => s.isNotEmpty && s.length > 2)
        .toList();
    final validKnownDirectors = knownDirectors
        .map(_normalizeText)
        .where((s) => s.isNotEmpty && s.length > 2)
        .toList();

    final tmdbPeople = <String>[
      ...candidate.cast.map((c) => _normalizeText(c.name)),
      ...candidate.directors.map(_normalizeText),
    ].where((s) => s.isNotEmpty).toList();

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

    // Nếu cả nguồn gốc và TMDb đều có dàn diễn viên rõ ràng (>=2 vs >=3) -> BẮT BUỘC trùng ít nhất 1 người
    // Ngăn chặn triệt để lỗi trùng tên + trùng năm giữa 2 phim khác nhau (ví dụ The Odyssey 2026)
    if (validKnownActors.length >= 2 && candidate.cast.length >= 3) {
      if (!hasPersonMatch) {
        debugPrint(
          'TMDB Match REJECTED for "$title": 0/${validKnownActors.length} actors matched against TMDb #${candidate.id} (${candidate.title})',
        );
        return false;
      }
      return true;
    }

    if (hasPersonMatch) return true;

    // Khi thiếu dữ liệu diễn viên: yêu cầu khớp tiêu đề chuẩn hóa + năm hợp lệ (±1)
    final tmdbTitle = _normalizeText(candidate.title ?? '');
    final tmdbOrigTitle = _normalizeText(candidate.originalTitle ?? '');
    final normTitle = _normalizeText(_sanitizeTitle(title));
    final normOrig = originName != null ? _normalizeText(_sanitizeTitle(originName)) : '';

    final titleMatches = normTitle.isNotEmpty && (tmdbTitle == normTitle || tmdbOrigTitle == normTitle);
    final origMatches = normOrig.isNotEmpty &&
        normOrig.split(' ').length > 1 &&
        (tmdbTitle == normOrig || tmdbOrigTitle == normOrig);

    if (!titleMatches && !origMatches) {
      return false;
    }

    if (year != null && year > 0 && candidate.year != null && candidate.year! > 0) {
      if ((year - candidate.year!).abs() > 1) {
        return false;
      }
    }

    return true;
  }

  /// Tra cứu bổ sung thông tin từ TMDB (ưu tiên tmdbId trực tiếp, fallback tìm theo tên + Cross-Validation)
  Future<TmdbMovieData?> enrichMovie({
    required String title,
    String? originName,
    int? year,
    List<String> knownActors = const [],
    List<String> knownDirectors = const [],
    int? tmdbId,
    String? mediaType,
    String? expectedType,
  }) async {
    final cacheKey = '${tmdbId ?? ''}_${mediaType ?? ''}_${title}_${originName ?? ''}_${year ?? ''}'.toLowerCase();
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    try {
      // 1. Ưu tiên tra cứu trực tiếp bằng tmdbId từ nguồn KKPhim (chính xác 100%, chỉ 1 HTTP request)
      if (tmdbId != null && tmdbId > 0) {
        final targetType = (mediaType == 'tv' || mediaType == 'movie')
            ? mediaType!
            : (expectedType == 'series' ? 'tv' : 'movie');
        final direct = await getDetailById(tmdbId, targetType);
        if (direct != null) {
          // Kiểm tra nhanh chống lỗi gõ nhầm ID từ upstream
          final validActors = knownActors.map(_normalizeText).where((s) => s.length > 2).toList();
          if (validActors.length >= 2 && direct.cast.length >= 3) {
            final passesCast = _passesCrossValidation(
              direct,
              title: title,
              originName: originName,
              year: year,
              knownActors: knownActors,
              knownDirectors: knownDirectors,
            );
            final normTmdbTitle = _normalizeText(direct.title ?? '');
            final normTmdbOrig = _normalizeText(direct.originalTitle ?? '');
            final normSrcTitle = _normalizeText(_sanitizeTitle(title));
            final normSrcOrig = originName != null ? _normalizeText(_sanitizeTitle(originName)) : '';
            final titleRoughMatch = (normSrcTitle.isNotEmpty && (normTmdbTitle.contains(normSrcTitle) || normSrcTitle.contains(normTmdbTitle))) ||
                (normSrcOrig.isNotEmpty && (normTmdbOrig.contains(normSrcOrig) || normSrcOrig.contains(normTmdbOrig)));
            if (passesCast || titleRoughMatch) {
              _memoryCache[cacheKey] = direct;
              return direct;
            }
          } else {
            _memoryCache[cacheKey] = direct;
            return direct;
          }
        }
      }

      // 2. Fallback: Tìm kiếm theo tên trên TMDb
      final queriesToTry = <String>[];
      final cleanTitle = _sanitizeTitle(title);
      final cleanOrigin = originName != null ? _sanitizeTitle(originName) : '';

      if (cleanOrigin.isNotEmpty) {
        final originWords = cleanOrigin.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (originWords.length > 1 || cleanOrigin.length >= 6) {
          queriesToTry.add(cleanOrigin);
        }
      }
      if (cleanTitle.isNotEmpty && !queriesToTry.contains(cleanTitle)) {
        queriesToTry.add(cleanTitle);
      }
      if (queriesToTry.isEmpty && cleanOrigin.isNotEmpty) {
        queriesToTry.add(cleanOrigin);
      }

      final preferredMediaType = (expectedType == 'series' || expectedType == 'tvshows') ? 'tv' : (expectedType == 'single' ? 'movie' : null);
      final candidates = <Map<String, dynamic>>[];
      final seenIds = <int>{};

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
          for (final item in results) {
            final mt = item['media_type']?.toString();
            final id = item['id'];
            if ((mt == 'movie' || mt == 'tv') && id is int && seenIds.add(id)) {
              candidates.add(Map<String, dynamic>.from(item as Map));
            }
          }
        }
        if (candidates.length >= 5) break;
      }

      if (candidates.isEmpty) return null;

      // Chấm điểm ứng viên: ưu tiên đúng mediaType, đúng năm, đúng tên
      final normTitle = _normalizeText(cleanTitle);
      final normOrigin = _normalizeText(cleanOrigin);

      int scoreCandidate(Map<String, dynamic> c) {
        int score = 0;
        final mt = c['media_type']?.toString();
        if (preferredMediaType != null && mt == preferredMediaType) score += 6;

        final cTitle = _normalizeText(c['title']?.toString() ?? c['name']?.toString() ?? '');
        final cOrig = _normalizeText(c['original_title']?.toString() ?? c['original_name']?.toString() ?? '');
        if ((normOrigin.isNotEmpty && (cOrig == normOrigin || cTitle == normOrigin)) ||
            (normTitle.isNotEmpty && (cTitle == normTitle || cOrig == normTitle))) {
          score += 10;
        }

        final date = (c['release_date'] ?? c['first_air_date'])?.toString() ?? '';
        final cYear = int.tryParse(date.split('-').first);
        if (year != null && year > 0 && cYear != null) {
          if (cYear == year) {
            score += 10;
          } else if ((cYear - year).abs() <= 1) {
            score += 4;
          } else if ((cYear - year).abs() > 2) {
            score -= 8;
          }
        }
        return score;
      }

      candidates.sort((a, b) => scoreCandidate(b).compareTo(scoreCandidate(a)));

      // Thử tối đa 3 ứng viên hàng đầu & kiểm duyệt chéo
      for (final candidate in candidates.take(3)) {
        final cid = candidate['id'] as int;
        final cType = candidate['media_type']?.toString() ?? 'movie';
        final detail = await getDetailById(cid, cType);
        if (detail == null) continue;

        if (_passesCrossValidation(
          detail,
          title: title,
          originName: originName,
          year: year,
          knownActors: knownActors,
          knownDirectors: knownDirectors,
        )) {
          _memoryCache[cacheKey] = detail;
          return detail;
        }
      }

      return null;
    } catch (e) {
      debugPrint('TMDB Enrich error for $title: $e');
      return null;
    }
  }

  /// Lấy danh sách phim đề xuất chuẩn MovieItem từ TMDb Recommendations API
  Future<List<MovieItem>> getRecommendations({
    required int tmdbId,
    required String mediaType,
  }) async {
    try {
      final cleanType = mediaType == 'tv' ? 'tv' : 'movie';
      final res = await _dio.get(
        '/$cleanType/$tmdbId/recommendations',
        queryParameters: {
          'language': 'vi-VN',
          'page': 1,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final results = res.data['results'] as List? ?? [];
        return results
            .whereType<Map>()
            .map((item) => MovieItem.fromTmdb(
                  Map<String, dynamic>.from(item),
                  mediaType: item['media_type']?.toString() ?? cleanType,
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('TMDb getRecommendations error: $e');
    }
    return [];
  }

  /// Lấy danh sách tên phim đề xuất từ TMDb Recommendations API
  Future<List<String>> getRecommendedTitles({
    required int tmdbId,
    required String mediaType, // 'movie' or 'tv'
  }) async {
    try {
      final res = await _dio.get(
        '/$mediaType/$tmdbId/recommendations',
        queryParameters: {
          'language': 'vi-VN',
          'page': 1,
        },
      );

      if (res.statusCode == 200 && res.data != null) {
        final results = res.data['results'] as List? ?? [];
        final titles = <String>[];
        for (final item in results) {
          final viTitle = item['title']?.toString() ?? item['name']?.toString() ?? '';
          final origTitle = item['original_title']?.toString() ?? item['original_name']?.toString() ?? '';
          if (viTitle.isNotEmpty && !titles.contains(viTitle)) {
            titles.add(viTitle);
          }
          if (origTitle.isNotEmpty && !titles.contains(origTitle)) {
            titles.add(origTitle);
          }
        }
        return titles;
      }
    } catch (e) {
      debugPrint('TMDb getRecommendedTitles error: $e');
    }
    return [];
  }

  /// Tìm kiếm hồ sơ diễn viên theo tên trên TMDb
  Future<TmdbPersonDetails?> searchPerson(String name) async {
    try {
      final res = await _dio.get(
        '/search/person',
        queryParameters: {
          'query': name,
          'language': 'vi-VN',
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final results = res.data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          final first = results.first;
          final personId = first['id'] as int;
          return await getPersonDetails(personId);
        }
      }
    } catch (e) {
      debugPrint('TMDb searchPerson error: $e');
    }
    return null;
  }

  /// Tra cứu trọn bộ sưu tập điện ảnh (Movie Collection / Franchise)
  Future<TmdbCollection?> getCollection(int collectionId) async {
    try {
      final res = await _dio.get(
        '/collection/$collectionId',
        queryParameters: {'language': 'vi-VN'},
      );
      if (res.statusCode == 200 && res.data != null) {
        return TmdbCollection.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('TMDb getCollection error: $e');
    }
    return null;
  }

  /// Tra cứu hồ sơ diễn viên & toàn bộ phim tham gia (Person Filmography)
  Future<TmdbPersonDetails?> getPersonDetails(int personId) async {
    try {
      final res = await _dio.get(
        '/person/$personId',
        queryParameters: {
          'language': 'vi-VN',
          'append_to_response': 'combined_credits',
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final profilePath = data['profile_path']?.toString();
        final rawCredits = data['combined_credits']?['cast'] as List? ?? [];
        final credits = rawCredits
            .map((c) => TmdbPersonCredit.fromJson(c as Map<String, dynamic>))
            .where((c) => c.title.isNotEmpty)
            .toList();

        // Sắp xếp các phim theo độ phổ biến / voteCount giảm dần
        credits.sort((a, b) => b.voteCount.compareTo(a.voteCount));

        return TmdbPersonDetails(
          id: personId,
          name: data['name']?.toString() ?? '',
          biography: data['biography']?.toString() ?? '',
          birthday: data['birthday']?.toString(),
          placeOfBirth: data['place_of_birth']?.toString(),
          profileUrl: (profilePath != null && profilePath.isNotEmpty)
              ? 'https://image.tmdb.org/t/p/h632$profilePath'
              : null,
          knownForDepartment: data['known_for_department']?.toString(),
          credits: credits,
        );
      }
    } catch (e) {
      debugPrint('TMDb getPersonDetails error: $e');
    }
    return null;
  }

  /// Lấy danh sách đánh giá từ cộng đồng quốc tế (Reviews)
  Future<List<TmdbReview>> getMovieReviews(int tmdbId, String mediaType) async {
    try {
      // Ưu tiên tiếng Việt, nếu không có lấy tiếng Anh
      var res = await _dio.get(
        '/$mediaType/$tmdbId/reviews',
        queryParameters: {'language': 'vi-VN'},
      );

      var results = res.data?['results'] as List? ?? [];
      if (results.isEmpty) {
        res = await _dio.get(
          '/$mediaType/$tmdbId/reviews',
          queryParameters: {'language': 'en-US'},
        );
        results = res.data?['results'] as List? ?? [];
      }

      if (results.isNotEmpty) {
        return results.map((r) => TmdbReview.fromJson(r as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('TMDb getMovieReviews error: $e');
    }
    return [];
  }

  /// Lấy danh sách phim xu hướng thịnh hành toàn cầu chuẩn TMDb (trực tiếp MovieItem, cache + dedup)
  Future<List<MovieItem>> getTrendingItems({
    String mediaType = 'all',
    String timeWindow = 'week',
  }) async {
    final key = '${mediaType}_$timeWindow';
    final cached = _trendingCache[key];
    if (cached != null && DateTime.now().difference(cached.ts).inMinutes < 10) {
      return cached.items;
    }
    if (_inFlightTrending.containsKey(key)) {
      return await _inFlightTrending[key]!;
    }

    final future = () async {
      try {
        final res = await _dio.get(
          '/trending/$mediaType/$timeWindow',
          queryParameters: {'language': 'vi-VN'},
        );
        if (res.statusCode == 200 && res.data != null) {
          final results = res.data['results'] as List? ?? [];
          final items = <MovieItem>[];
          for (final raw in results) {
            if (raw is! Map) continue;
            final mt = raw['media_type']?.toString() ?? (mediaType == 'all' ? 'movie' : mediaType);
            if (mt != 'movie' && mt != 'tv') continue;
            items.add(MovieItem.fromTmdb(Map<String, dynamic>.from(raw), mediaType: mt));
          }
          _trendingCache[key] = (items: items, ts: DateTime.now());
          return items;
        }
      } catch (e) {
        debugPrint('TMDb getTrendingItems error: $e');
      }
      return <MovieItem>[];
    }();

    _inFlightTrending[key] = future;
    try {
      return await future;
    } finally {
      _inFlightTrending.remove(key);
    }
  }

  /// Lấy danh sách phim xu hướng thịnh hành toàn cầu (All / Movie / TV, Day / Week)
  Future<List<String>> getTrending({String mediaType = 'all', String timeWindow = 'week'}) async {
    try {
      final res = await _dio.get(
        '/trending/$mediaType/$timeWindow',
        queryParameters: {'language': 'vi-VN'},
      );
      if (res.statusCode == 200 && res.data != null) {
        final results = res.data['results'] as List? ?? [];
        final titles = <String>[];
        for (final item in results) {
          final viTitle = item['title']?.toString() ?? item['name']?.toString() ?? '';
          final origTitle = item['original_title']?.toString() ?? item['original_name']?.toString() ?? '';
          if (viTitle.isNotEmpty && !titles.contains(viTitle)) {
            titles.add(viTitle);
          } else if (origTitle.isNotEmpty && !titles.contains(origTitle)) {
            titles.add(origTitle);
          }
        }
        return titles;
      }
    } catch (e) {
      debugPrint('TMDb getTrending error: $e');
    }
    return [];
  }

  /// Lấy danh sách nghệ sĩ / diễn viên đang thịnh hành toàn cầu (Trending Persons)
  Future<List<TmdbCast>> getTrendingPersons({String timeWindow = 'week'}) async {
    try {
      final res = await _dio.get(
        '/trending/person/$timeWindow',
        queryParameters: {'language': 'vi-VN'},
      );
      if (res.statusCode == 200 && res.data != null) {
        final results = res.data['results'] as List? ?? [];
        return results.map((e) {
          final profilePath = e['profile_path']?.toString();
          final knownFor = e['known_for_department']?.toString() ?? 'Diễn viên';
          return TmdbCast(
            id: e['id'] is int ? e['id'] : 0,
            name: e['name']?.toString() ?? '',
            character: knownFor,
            profileUrl: (profilePath != null && profilePath.isNotEmpty)
                ? 'https://image.tmdb.org/t/p/w185$profilePath'
                : null,
          );
        }).where((p) => p.name.isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint('TMDb getTrendingPersons error: $e');
    }
    return [];
  }

  /// Khám phá phim TMDb nâng cao theo bộ lọc đa chiều (Discover Movie / TV)
  Future<List<MovieItem>> discover({
    String mediaType = 'movie', // 'movie' or 'tv'
    String sortBy = 'popularity.desc',
    String? genreId,
    String? originalLanguage,
    String? originCountry,
    String? year,
    double? minRating,
    int page = 1,
  }) async {
    try {
      final endpoint = mediaType == 'tv' ? '/discover/tv' : '/discover/movie';
      final params = <String, dynamic>{
        'language': 'vi-VN',
        'page': page,
        'sort_by': sortBy,
        'include_adult': false,
      };
      if (genreId != null && genreId.isNotEmpty && genreId != 'all') {
        params['with_genres'] = genreId;
      }
      if (originalLanguage != null && originalLanguage.isNotEmpty && originalLanguage != 'all') {
        params['with_original_language'] = originalLanguage;
      }
      if (originCountry != null && originCountry.isNotEmpty && originCountry != 'all') {
        params['with_origin_country'] = originCountry;
      }
      if (year != null && year.isNotEmpty && year != 'all') {
        if (mediaType == 'tv') {
          params['first_air_date_year'] = year;
        } else {
          params['primary_release_year'] = year;
        }
      }
      if (minRating != null && minRating > 0) {
        params['vote_average.gte'] = minRating;
        params['vote_count.gte'] = 25; // Đảm bảo phim có uy tín
      }

      final res = await _dio.get(endpoint, queryParameters: params);
      if (res.statusCode == 200 && res.data != null) {
        final results = res.data['results'] as List? ?? [];
        return results.map((item) {
          return MovieItem.fromTmdb(Map<String, dynamic>.from(item), mediaType: mediaType);
        }).toList();
      }
    } catch (e) {
      debugPrint('TMDb discover error: $e');
    }
    return [];
  }

  /// Tìm kiếm đa năng TMDb (Multi-Search: Movie & TV)
  Future<List<MovieItem>> searchMulti(String query, {int page = 1, String? year}) async {
    try {
      final params = <String, dynamic>{
        'query': query,
        'language': 'vi-VN',
        'page': page,
        'include_adult': false,
      };
      if (year != null && year.isNotEmpty && year != 'all') {
        params['year'] = year;
      }
      final res = await _dio.get('/search/multi', queryParameters: params);
      if (res.statusCode == 200 && res.data != null) {
        final results = res.data['results'] as List? ?? [];
        final list = <MovieItem>[];
        for (final item in results) {
          final mediaType = item['media_type']?.toString();
          if (mediaType == 'movie' || mediaType == 'tv') {
            list.add(MovieItem.fromTmdb(Map<String, dynamic>.from(item), mediaType: mediaType ?? 'movie'));
          }
        }
        return list;
      }
    } catch (e) {
      debugPrint('TMDb searchMulti error: $e');
    }
    return [];
  }
}
