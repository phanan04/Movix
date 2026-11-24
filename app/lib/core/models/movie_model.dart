import '../services/tmdb_service.dart';

class MovieCategoryItem {
  final String id;
  final String name;
  final String slug;

  const MovieCategoryItem({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory MovieCategoryItem.fromJson(Map<String, dynamic> json) {
    return MovieCategoryItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
  };
}

class EpisodeItem {
  final String name;
  final String slug;
  final String filename;
  final String linkEmbed;
  final String linkM3u8;

  const EpisodeItem({
    required this.name,
    required this.slug,
    required this.filename,
    required this.linkEmbed,
    required this.linkM3u8,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    var embed = json['link_embed']?.toString() ?? json['embed']?.toString() ?? '';
    var m3u8 = json['link_m3u8']?.toString() ?? json['m3u8']?.toString() ?? '';

    // Tự động trích xuất trực tiếp HLS m3u8 từ VSMov Stream Embed
    if (m3u8.isEmpty && embed.isNotEmpty) {
      final vsmovMatch = RegExp(r'(https?://[^/]+\.streamvsmov\.com)/video/([a-zA-Z0-9\-]+)').firstMatch(embed);
      if (vsmovMatch != null) {
        final host = vsmovMatch.group(1);
        final hash = vsmovMatch.group(2);
        m3u8 = '$host/stream/$hash/master.m3u8';
      } else if (embed.contains('.m3u8')) {
        m3u8 = embed;
      }
    }

    return EpisodeItem(
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      linkEmbed: embed,
      linkM3u8: m3u8,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'slug': slug,
    'filename': filename,
    'link_embed': linkEmbed,
    'link_m3u8': linkM3u8,
  };
}

class EpisodeServer {
  final String serverName;
  final List<EpisodeItem> serverData;

  const EpisodeServer({
    required this.serverName,
    required this.serverData,
  });

  factory EpisodeServer.fromJson(Map<String, dynamic> json) {
    final rawData = json['server_data'] ?? json['items'] ?? [];
    final items = <EpisodeItem>[];
    if (rawData is List) {
      for (final it in rawData) {
        if (it is Map<String, dynamic>) {
          items.add(EpisodeItem.fromJson(it));
        }
      }
    }
    final rawName = json['server_name']?.toString() ?? 'Server 1';
    final cleanName = rawName.replaceAll(RegExp(r'\s+'), ' ').trim();
    return EpisodeServer(
      serverName: cleanName.isNotEmpty ? cleanName : 'Server 1',
      serverData: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'server_name': serverName,
    'server_data': serverData.map((e) => e.toJson()).toList(),
  };
}

class MovieItem {
  final String id;
  final String name;
  final String originName;
  final String slug;
  final String thumbUrl;
  final String posterUrl;
  final int year;
  final String episodeCurrent;
  final String quality;
  final String lang;
  final String time;
  final List<String> categoryNames;
  final double voteAverage;

  const MovieItem({
    required this.id,
    required this.name,
    required this.originName,
    required this.slug,
    required this.thumbUrl,
    required this.posterUrl,
    required this.year,
    required this.episodeCurrent,
    required this.quality,
    required this.lang,
    this.time = '',
    this.categoryNames = const [],
    this.voteAverage = 0.0,
  });

  String get ratingDisplay {
    if (voteAverage > 0) {
      return voteAverage.toStringAsFixed(1);
    }
    return quality.isNotEmpty ? quality : 'FHD';
  }

  String get fullThumbUrl {
    if (thumbUrl.isEmpty) return '';
    if (thumbUrl.startsWith('http://') || thumbUrl.startsWith('https://')) {
      return thumbUrl;
    }
    return 'https://phimimg.com/$thumbUrl';
  }

  String get fullPosterUrl {
    if (posterUrl.isEmpty) return fullThumbUrl;
    if (posterUrl.startsWith('http://') || posterUrl.startsWith('https://')) {
      return posterUrl;
    }
    return 'https://phimimg.com/$posterUrl';
  }

  /// Ảnh nền ngang (Backdrop 16:9) chuẩn cho Hero Banner, Chi tiết phim và Player
  String get backdropUrl {
    if (fullThumbUrl.isNotEmpty) return fullThumbUrl;
    return fullPosterUrl;
  }

  /// Ảnh áp phích dọc (Poster 2:3) chuẩn cho Poster card, danh sách phim
  String get verticalPosterUrl {
    if (fullPosterUrl.isNotEmpty) return fullPosterUrl;
    return fullThumbUrl;
  }

  factory MovieItem.fromJson(Map<String, dynamic> json) {
    List<String> categories = [];
    if (json['category'] is List) {
      for (final c in json['category']) {
        if (c is Map && c['name'] != null) {
          categories.add(c['name'].toString());
        } else if (c is String) {
          categories.add(c);
        }
      }
    }

    final rawTmdb = json['tmdb'];
    final rawImdb = json['imdb'];
    double parsedVote = 0.0;
    if (rawTmdb is Map && rawTmdb['vote_average'] != null) {
      parsedVote = double.tryParse(rawTmdb['vote_average'].toString()) ?? 0.0;
    } else if (rawImdb is Map && rawImdb['vote_average'] != null) {
      parsedVote = double.tryParse(rawImdb['vote_average'].toString()) ?? 0.0;
    }

    return MovieItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      originName: json['origin_name']?.toString() ?? json['original_name']?.toString() ?? json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      thumbUrl: json['thumb_url']?.toString() ?? json['poster_url']?.toString() ?? '',
      posterUrl: json['poster_url']?.toString() ?? json['thumb_url']?.toString() ?? '',
      year: int.tryParse(json['year']?.toString() ?? '') ?? 2024,
      episodeCurrent: json['episode_current']?.toString() ?? json['current_episode']?.toString() ?? '',
      quality: json['quality']?.toString() ?? 'FHD',
      lang: json['lang']?.toString() ?? json['language']?.toString() ?? 'Vietsub',
      time: json['time']?.toString() ?? '',
      categoryNames: categories,
      voteAverage: parsedVote,
    );
  }

  factory MovieItem.fromTmdb(Map<String, dynamic> json, {String mediaType = 'movie'}) {
    final title = json['title']?.toString() ?? json['name']?.toString() ?? '';
    final originalTitle = json['original_title']?.toString() ?? json['original_name']?.toString() ?? title;
    final posterPath = json['poster_path']?.toString();
    final backdropPath = json['backdrop_path']?.toString();
    final releaseDate = json['release_date']?.toString() ?? json['first_air_date']?.toString() ?? '';
    final year = int.tryParse(releaseDate.split('-').first) ?? 2024;
    final vote = (json['vote_average'] is num) ? (json['vote_average'] as num).toDouble() : 0.0;
    final id = json['id']?.toString() ?? '';

    // Tạo slug chuẩn từ tiêu đề
    String genSlug(String text) {
      var s = text.toLowerCase().trim();
      s = s.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
      s = s.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
      s = s.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
      s = s.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
      s = s.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
      s = s.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
      s = s.replaceAll(RegExp(r'[đ]'), 'd');
      s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
      s = s.replaceAll(RegExp(r'\s+'), '-');
      s = s.replaceAll(RegExp(r'-+'), '-');
      return s;
    }

    final slug = genSlug(originalTitle.isNotEmpty ? originalTitle : title);
    final poster = (posterPath != null && posterPath.isNotEmpty)
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : '';
    final backdrop = (backdropPath != null && backdropPath.isNotEmpty)
        ? 'https://image.tmdb.org/t/p/w780$backdropPath'
        : poster;

    final determinedMediaType = json['media_type']?.toString() ?? mediaType;

    return MovieItem(
      id: id,
      name: title.isNotEmpty ? title : originalTitle,
      originName: originalTitle,
      slug: slug.isNotEmpty ? slug : 'tmdb-$id',
      thumbUrl: backdrop,
      posterUrl: poster,
      year: year,
      episodeCurrent: determinedMediaType == 'tv' ? 'Series' : 'Full',
      quality: vote > 0 ? '${vote.toStringAsFixed(1)} ★' : 'FHD',
      lang: 'Quốc Tế',
      time: releaseDate,
      categoryNames: const [],
      voteAverage: vote,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'origin_name': originName,
    'slug': slug,
    'thumb_url': thumbUrl,
    'poster_url': posterUrl,
    'year': year,
    'episode_current': episodeCurrent,
    'quality': quality,
    'lang': lang,
    'time': time,
    'category': categoryNames,
  };
}

class MovieDetail {
  final String id;
  final String name;
  final String originName;
  final String slug;
  final String type; // single or series
  final String thumbUrl;
  final String posterUrl;
  final String time;
  final String episodeCurrent;
  final String episodeTotal;
  final String quality;
  final String lang;
  final int year;
  final String content;
  final List<String> actors;
  final List<String> directors;
  final List<MovieCategoryItem> categories;
  final List<EpisodeServer> episodes;
  final String? tmdbBackdropUrl;
  final String? tmdbPosterUrl;
  final double tmdbVoteAverage;
  final int tmdbVoteCount;
  final List<TmdbCast> tmdbCast;
  final int? tmdbId;
  final String? tmdbMediaType;
  final String? clearLogoUrl;
  final int? collectionId;
  final String? collectionName;
  final String? collectionBackdrop;
  final List<TmdbCompany> networks;
  final List<TmdbCompany> productionCompanies;

  const MovieDetail({
    required this.id,
    required this.name,
    required this.originName,
    required this.slug,
    required this.type,
    required this.thumbUrl,
    required this.posterUrl,
    required this.time,
    required this.episodeCurrent,
    required this.episodeTotal,
    required this.quality,
    required this.lang,
    required this.year,
    required this.content,
    required this.actors,
    required this.directors,
    required this.categories,
    required this.episodes,
    this.tmdbBackdropUrl,
    this.tmdbPosterUrl,
    this.tmdbVoteAverage = 0.0,
    this.tmdbVoteCount = 0,
    this.tmdbCast = const [],
    this.tmdbId,
    this.tmdbMediaType,
    this.clearLogoUrl,
    this.collectionId,
    this.collectionName,
    this.collectionBackdrop,
    this.networks = const [],
    this.productionCompanies = const [],
  });

  MovieDetail copyWithTmdb(TmdbMovieData tmdb) {
    return MovieDetail(
      id: id,
      name: name,
      originName: originName,
      slug: slug,
      type: type,
      thumbUrl: thumbUrl,
      posterUrl: posterUrl,
      time: time,
      episodeCurrent: episodeCurrent,
      episodeTotal: episodeTotal,
      quality: quality,
      lang: lang,
      year: year,
      content: content,
      actors: actors,
      directors: directors,
      categories: categories,
      episodes: episodes,
      tmdbBackdropUrl: tmdb.backdropUrl,
      tmdbPosterUrl: tmdb.posterUrl,
      tmdbVoteAverage: tmdb.voteAverage,
      tmdbVoteCount: tmdb.voteCount,
      tmdbCast: tmdb.cast,
      tmdbId: tmdb.id,
      tmdbMediaType: tmdb.mediaType,
      clearLogoUrl: tmdb.clearLogoUrl,
      collectionId: tmdb.collectionId,
      collectionName: tmdb.collectionName,
      collectionBackdrop: tmdb.collectionBackdrop,
      networks: tmdb.networks,
      productionCompanies: tmdb.productionCompanies,
    );
  }

  MovieDetail copyWithEpisodes(List<EpisodeServer> newEpisodes) {
    return MovieDetail(
      id: id,
      name: name,
      originName: originName,
      slug: slug,
      type: type,
      thumbUrl: thumbUrl,
      posterUrl: posterUrl,
      time: time,
      episodeCurrent: episodeCurrent,
      episodeTotal: episodeTotal,
      quality: quality,
      lang: lang,
      year: year,
      content: content,
      actors: actors,
      directors: directors,
      categories: categories,
      episodes: newEpisodes,
      tmdbBackdropUrl: tmdbBackdropUrl,
      tmdbPosterUrl: tmdbPosterUrl,
      tmdbVoteAverage: tmdbVoteAverage,
      tmdbVoteCount: tmdbVoteCount,
      tmdbCast: tmdbCast,
      tmdbId: tmdbId,
      tmdbMediaType: tmdbMediaType,
      clearLogoUrl: clearLogoUrl,
      collectionId: collectionId,
      collectionName: collectionName,
      collectionBackdrop: collectionBackdrop,
      networks: networks,
      productionCompanies: productionCompanies,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieDetail && runtimeType == other.runtimeType && slug == other.slug;

  @override
  int get hashCode => slug.hashCode;

  String get fullThumbUrl {
    if (thumbUrl.isEmpty) return '';
    if (thumbUrl.startsWith('http://') || thumbUrl.startsWith('https://')) {
      return thumbUrl;
    }
    return 'https://phimimg.com/$thumbUrl';
  }

  String get fullPosterUrl {
    if (posterUrl.isEmpty) return fullThumbUrl;
    if (posterUrl.startsWith('http://') || posterUrl.startsWith('https://')) {
      return posterUrl;
    }
    return 'https://phimimg.com/$posterUrl';
  }

  /// Ảnh nền ngang (Backdrop 16:9) chuẩn cho Hero Banner, Chi tiết phim và Player
  String get backdropUrl {
    if (tmdbBackdropUrl != null && tmdbBackdropUrl!.isNotEmpty) {
      return tmdbBackdropUrl!;
    }
    if (fullThumbUrl.isNotEmpty) return fullThumbUrl;
    return fullPosterUrl;
  }

  /// Ảnh áp phích dọc (Poster 2:3) chuẩn cho Poster card, danh sách phim
  String get verticalPosterUrl {
    if (tmdbPosterUrl != null && tmdbPosterUrl!.isNotEmpty) {
      return tmdbPosterUrl!;
    }
    if (fullPosterUrl.isNotEmpty) return fullPosterUrl;
    return fullThumbUrl;
  }

  double get voteAverage => tmdbVoteAverage > 0 ? tmdbVoteAverage : 0.0;
  int get voteCount => tmdbVoteCount;

  factory MovieDetail.fromJson(Map<String, dynamic> json, {List<EpisodeServer>? explicitEpisodes}) {
    final movie = json['movie'] ?? json;

    final cats = <MovieCategoryItem>[];
    if (movie['category'] is List) {
      for (final c in movie['category']) {
        if (c is Map<String, dynamic>) {
          cats.add(MovieCategoryItem.fromJson(c));
        }
      }
    }

    final rawActors = movie['actor'] ?? movie['casts'] ?? [];
    List<String> actorList = [];
    if (rawActors is List) {
      actorList = rawActors.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawActors is String) {
      actorList = rawActors.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    final rawDirs = movie['director'] ?? [];
    List<String> dirList = [];
    if (rawDirs is List) {
      dirList = rawDirs.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawDirs is String) {
      dirList = [rawDirs.trim()];
    }

    final epServers = explicitEpisodes ?? [];
    if (epServers.isEmpty && json['episodes'] is List) {
      for (final s in json['episodes']) {
        if (s is Map<String, dynamic>) {
          epServers.add(EpisodeServer.fromJson(s));
        }
      }
    }

    // Clean html tags from content
    final rawContent = movie['content']?.toString() ?? movie['description']?.toString() ?? '';
    final cleanContent = rawContent.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();

    return MovieDetail(
      id: movie['_id']?.toString() ?? movie['id']?.toString() ?? movie['slug']?.toString() ?? '',
      name: movie['name']?.toString() ?? '',
      originName: movie['origin_name']?.toString() ?? movie['name']?.toString() ?? '',
      slug: movie['slug']?.toString() ?? '',
      type: movie['type']?.toString() ?? 'single',
      thumbUrl: movie['thumb_url']?.toString() ?? movie['poster_url']?.toString() ?? '',
      posterUrl: movie['poster_url']?.toString() ?? movie['thumb_url']?.toString() ?? '',
      time: movie['time']?.toString() ?? '',
      episodeCurrent: movie['episode_current']?.toString() ?? '',
      episodeTotal: movie['episode_total']?.toString() ?? '',
      quality: movie['quality']?.toString() ?? 'FHD',
      lang: movie['lang']?.toString() ?? 'Vietsub',
      year: int.tryParse(movie['year']?.toString() ?? '') ?? 2024,
      content: cleanContent,
      actors: actorList,
      directors: dirList,
      categories: cats,
      episodes: epServers,
    );
  }
}
