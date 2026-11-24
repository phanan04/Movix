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

      // Truy vấn chi tiết kèm credits, video trailers, và images (logos)
      final detailRes = await _dio.get(
        '/$mediaType/$tmdbId',
        queryParameters: {
          'append_to_response': 'credits,videos,images',
          'include_image_language': 'vi,en,null',
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

      // 1. Logo PNG trong suốt (Clear Art Logo chuẩn Netflix / Apple TV)
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

      // 2. Thông tin Bộ sưu tập / Series (Belongs to collection)
      final collectionObj = data['belongs_to_collection'] as Map<String, dynamic>?;
      final collectionId = collectionObj?['id'] as int?;
      final collectionName = collectionObj?['name']?.toString();
      final collectionBackdrop = collectionObj?['backdrop_path']?.toString() != null
          ? 'https://image.tmdb.org/t/p/w1280${collectionObj!['backdrop_path']}'
          : null;

      // 3. Hãng sản xuất & Mạng lưới phát sóng (Networks / Production Companies)
      final rawNetworks = data['networks'] as List? ?? [];
      final networks = rawNetworks
          .map((n) => TmdbCompany.fromJson(n as Map<String, dynamic>))
          .toList();

      final rawProdCompanies = data['production_companies'] as List? ?? [];
      final productionCompanies = rawProdCompanies
          .map((c) => TmdbCompany.fromJson(c as Map<String, dynamic>))
          .toList();

      final enriched = TmdbMovieData(
        id: tmdbId,
        mediaType: mediaType,
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

      _memoryCache[cacheKey] = enriched;
      return enriched;
    } catch (e) {
      debugPrint('TMDB Enrich error for $title: $e');
      return null;
    }
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
