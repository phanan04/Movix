import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/phim_api_service.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/models/movie_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/movie_providers.dart';
import '../../widgets/cached_poster_image.dart';
import '../../widgets/episode_grid_widget.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/app_state_views.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/tv_focusable.dart';
import '../player/player_screen.dart';
import 'widgets/movie_comments_widget.dart';
import 'widgets/cast_list_widget.dart';
import 'widgets/collection_widget.dart';
import 'widgets/reviews_widget.dart';

enum DetailViewMode {
  overview,
  episodes,
  similar,
}

class MovieDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  final int? tmdbId;
  final String? tmdbMediaType;
  final MovieItem? previewMovie;
  final String? heroTag;

  const MovieDetailScreen({
    super.key,
    required this.slug,
    this.tmdbId,
    this.tmdbMediaType,
    this.previewMovie,
    this.heroTag,
  });

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  final UserStorage _userStorage = UserStorage();
  int _selectedServerIndex = 0;
  int _selectedChunkIndex = 0;
  bool _isDescriptionExpanded = false;
  DetailViewMode _viewMode = DetailViewMode.overview;
  int _focusedEpisodeIndex = 0;
  bool _isLiked = false;
  bool? _userSetEpisodeGridMode;
  int _selectedMobileFeedbackTab = 0;

  MovieDetailRequest get _detailRequest => MovieDetailRequest(
        slug: widget.slug,
        tmdbId: widget.tmdbId,
        tmdbMediaType: widget.tmdbMediaType,
        previewMovie: widget.previewMovie,
      );

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(movieDetailProvider(_detailRequest));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        data: (movie) => _buildContent(movie),
        loading: () => const MovieDetailSkeleton(),
        error: (err, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: AppErrorStateWidget(
            message: err.toString(),
            onRetry: () => ref.invalidate(movieDetailProvider(_detailRequest)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MovieDetail movie) {
    final movieItem = MovieItem(
      id: movie.id,
      name: movie.name,
      originName: movie.originName,
      slug: movie.slug,
      thumbUrl: movie.thumbUrl,
      posterUrl: movie.posterUrl,
      year: movie.year,
      episodeCurrent: movie.episodeCurrent,
      quality: movie.quality,
      lang: movie.lang,
      time: movie.time,
      categoryNames: movie.categories.map((c) => c.name).toList(),
      voteAverage: movie.voteAverage,
      tmdbId: movie.tmdbId,
      tmdbMediaType: movie.tmdbMediaType,
    );

    final episodes = movie.episodes.isNotEmpty
        ? (_selectedServerIndex < movie.episodes.length
            ? movie.episodes[_selectedServerIndex].serverData
            : movie.episodes.first.serverData)
        : <EpisodeItem>[];

    // Check watch progress to resume
    final progress = _userStorage.getProgress(movie.slug);

    // Tự động nhảy sang trang tab khoảng tập tương ứng của tập đang xem dở
    if (_selectedChunkIndex == 0 && progress != null && progress.episodeSlug.isNotEmpty && episodes.isNotEmpty) {
      final epIdx = episodes.indexWhere((e) => e.slug == progress.episodeSlug);
      if (epIdx >= 0) {
        _selectedChunkIndex = epIdx ~/ 20;
      }
    }

    final isTabletLandscape = MediaQuery.of(context).size.width >= 600;
    if (isTabletLandscape) {
      return _buildTabletLandscapeContent(movie, movieItem, episodes, progress);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(movieDetailProvider(_detailRequest));
        return ref.read(movieDetailProvider(_detailRequest).future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
        // 1. Collapsing Backdrop Header with Back & Bookmark
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            ValueListenableBuilder<List<MovieItem>>(
              valueListenable: _userStorage.myListNotifier,
              builder: (context, _, __) {
                final inList = _userStorage.isInMyList(movie.slug, tmdbId: movie.tmdbId);
                return IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: PopIconSwitch(
                      child: Icon(
                        inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        key: ValueKey(inList),
                        color: inList ? AppColors.primary : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  onPressed: () {
                    _userStorage.toggleMyList(movieItem);
                  },
                );
              },
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
              ),
              onPressed: () {
                AppToast.show(context, 'Đã sao chép liên kết phim', icon: Icons.link_rounded);
              },
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.heroTag != null)
                  Hero(
                    tag: widget.heroTag!,
                    child: CachedPosterImage(
                      imageUrl: movie.backdropUrl.isNotEmpty ? movie.backdropUrl : movie.verticalPosterUrl,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0.0, -0.15),
                    ),
                  )
                else
                  CachedPosterImage(
                    imageUrl: movie.backdropUrl.isNotEmpty ? movie.backdropUrl : movie.verticalPosterUrl,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.0, -0.15),
                  ),
                Container(
                  color: Colors.black.withValues(alpha: 0.18),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x800F1014),
                        Colors.transparent,
                        Color(0xE60F1014),
                        Color(0xFF0F1014),
                      ],
                      stops: [0.0, 0.35, 0.82, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Info and Action Details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title or Clear Logo (Feature 4)
                if (movie.clearLogoUrl != null && movie.clearLogoUrl!.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 65, maxWidth: 260),
                    child: CachedPosterImage(
                      imageUrl: movie.clearLogoUrl!,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(height: 6),
                ] else ...[
                  Text(
                    movie.name.split('/').first.trim(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ],
                if (movie.originName.isNotEmpty && (movie.clearLogoUrl != null || movie.originName != movie.name)) ...[
                  const SizedBox(height: 4),
                  Text(
                    movie.originName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Metadata Badges (Rating, Year, Quality, Time, Studios)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (movie.voteAverage > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F222A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF35383F), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 13),
                            const SizedBox(width: 3),
                            Text(
                              movie.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    else
                      const RatingBadge(rating: '9.8', isRed: true),
                    if (movie.year > 0)
                      Text('${movie.year}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white38, width: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        movie.quality.isNotEmpty ? movie.quality : 'HD',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white38, width: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        movie.lang.isNotEmpty ? movie.lang : 'Vietsub',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (movie.time.isNotEmpty)
                      Text(
                        movie.time,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    // Hãng sản xuất & Mạng lưới phát sóng (Feature 6)
                    if (movie.networks.isNotEmpty || movie.productionCompanies.isNotEmpty) ...[
                      ...[...movie.networks, ...movie.productionCompanies].take(2).map((comp) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white24, width: 0.6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (comp.logoUrl != null) ...[
                                CachedPosterImage(
                                  imageUrl: comp.logoUrl!,
                                  height: 11,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                comp.name,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Categories Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: movie.categories.map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Main Play / Resume Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (episodes.isNotEmpty) {
                        final resumeEp = progress != null
                            ? episodes.firstWhere(
                                (e) => e.slug == progress.episodeSlug,
                                orElse: () => episodes.first,
                              )
                            : episodes.first;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerScreen(
                              movie: movie,
                              episode: resumeEp,
                              allEpisodes: episodes,
                              initialPositionSeconds: progress?.positionSeconds ?? 0,
                            ),
                          ),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      } else {
                        AppToast.show(context, 'Phim hiện chưa có nguồn phát trực tuyến', icon: Icons.info_outline_rounded);
                      }
                    },
                    icon: Icon(
                      episodes.isNotEmpty ? Icons.play_arrow_rounded : Icons.schedule_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: Text(
                      episodes.isEmpty
                          ? 'Chưa có nguồn phát'
                          : (progress != null
                              ? (progress.positionSeconds > 10
                                  ? 'Tiếp tục xem: ${progress.episodeName.isNotEmpty ? progress.episodeName : "Tập ${progress.episodeSlug}"}'
                                  : 'Xem: ${progress.episodeName.isNotEmpty ? progress.episodeName : "Tập ${progress.episodeSlug}"}')
                              : 'Xem ${episodes.first.name}'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: episodes.isNotEmpty ? AppColors.primary : const Color(0xFF2B2E38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Mobile Action Bar: Danh sách, Thích, Chia sẻ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ValueListenableBuilder<List<MovieItem>>(
                      valueListenable: _userStorage.myListNotifier,
                      builder: (context, _, __) {
                        final inList = _userStorage.isInMyList(movie.slug, tmdbId: movie.tmdbId);
                        return _buildMobileActionItem(
                          icon: inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          label: 'Danh sách',
                          color: inList ? AppColors.primary : AppColors.textPrimary,
                          onTap: () => _userStorage.toggleMyList(movieItem),
                        );
                      },
                    ),
                    _buildMobileActionItem(
                      icon: _isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                      label: 'Thích',
                      color: _isLiked ? AppColors.primary : AppColors.textPrimary,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isLiked = !_isLiked);
                      },
                    ),
                    _buildMobileActionItem(
                      icon: Icons.share_outlined,
                      label: 'Chia sẻ',
                      color: Colors.white,
                      onTap: () => AppToast.show(context, 'Đã sao chép liên kết phim', icon: Icons.link_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Storyline / Content
                const Text(
                  'Nội dung phim',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  movie.content.isNotEmpty ? movie.content : 'Chưa có tóm tắt cho phim này.',
                  maxLines: _isDescriptionExpanded ? 100 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (movie.content.length > 120) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: Text(
                      _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Diễn viên & Nhân vật (TMDB Cast list with headshot avatars)
                CastListWidget(
                  tmdbCast: movie.tmdbCast,
                  fallbackActors: movie.actors,
                ),
                const SizedBox(height: 20),

                // Trọn bộ sưu tập / Franchise (Feature 3)
                if (movie.collectionId != null) ...[
                  CollectionWidget(
                    collectionId: movie.collectionId!,
                    collectionName: movie.collectionName ?? '',
                    currentMovieSlug: movie.slug,
                  ),
                  const SizedBox(height: 20),
                ],

                // Server Switcher
                if (movie.episodes.length > 1) ...[
                  const Text(
                    'Chọn máy chủ phát',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: movie.episodes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final s = movie.episodes[idx];
                        final isSelected = _selectedServerIndex == idx;
                        return ChoiceChip(
                          label: Text(s.serverName),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedServerIndex = idx;
                            });
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Danh sách tập phim (Episodes List - Clean Responsive Grid)
                EpisodeGridWidget(
                  episodes: episodes,
                  currentEpisodeSlug: progress?.episodeSlug,
                  onEpisodeSelected: (ep) {
                    final isPlayingThis = progress?.episodeSlug == ep.slug;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          movie: movie,
                          episode: ep,
                          allEpisodes: episodes,
                          initialPositionSeconds: isPlayingThis ? (progress?.positionSeconds ?? 0) : 0,
                        ),
                      ),
                    );
                  },
                ),

                // Comments & International Reviews Section (Feature 7)
                const SizedBox(height: 28),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedMobileFeedbackTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedMobileFeedbackTab == 0 ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedMobileFeedbackTab == 0 ? AppColors.primary : Colors.white12,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Bình luận Movix',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedMobileFeedbackTab == 0 ? FontWeight.bold : FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _selectedMobileFeedbackTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedMobileFeedbackTab == 1 ? AppColors.primary : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedMobileFeedbackTab == 1 ? AppColors.primary : AppColors.borderSubtle,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: _selectedMobileFeedbackTab == 1 ? Colors.white : AppColors.star,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Đánh giá quốc tế (TMDb)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedMobileFeedbackTab == 1 ? FontWeight.bold : FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_selectedMobileFeedbackTab == 0)
                  MovieCommentsWidget(movieSlug: movie.slug)
                else
                  MovieReviewsWidget(movie: movie),

                // 5. Phim tương tự & Đề xuất (TMDb Smart Match)
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Text(
                      'Phim tương tự',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.primaryBorder, width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLight, size: 11),
                          SizedBox(width: 3),
                          Text(
                            'TMDb',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final similarAsync = ref.watch(similarMoviesProvider(movie));
                    return similarAsync.when(
                      data: (movies) {
                        final filtered = movies.where((m) => m.slug != movie.slug).toList();
                        if (filtered.isEmpty) return const SizedBox.shrink();
                        return SizedBox(
                          height: 205,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, idx) {
                              return MovieCard(
                                movie: filtered[idx],
                                width: 115,
                                height: 160,
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const MovieCarouselSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  }

  Widget _buildTabletLandscapeContent(
    MovieDetail movie,
    MovieItem movieItem,
    List<EpisodeItem> episodes,
    WatchProgress? progress,
  ) {
    return PopScope(
      canPop: _viewMode == DetailViewMode.overview,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() {
            _viewMode = DetailViewMode.overview;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1014),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Hero Backdrop tràn viền toàn màn hình (Dưới cùng) độ nét cao chuẩn điện ảnh
            Positioned.fill(
              child: CachedPosterImage(
                imageUrl: movie.backdropUrl.isNotEmpty ? movie.backdropUrl : movie.verticalPosterUrl,
                fit: BoxFit.cover,
                alignment: const Alignment(0.15, -0.05),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // 1.5. Lớp làm dịu ánh sáng toàn màn hình (Soft Dimmer 18% chống chói cho poster sáng/trắng)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.18),
                ),
              ),
            ),

            // 2. Lớp LinearGradient ngang chuẩn Netflix (tối sâu bên trái, chuyển tiếp mượt mà và trong suốt sang bên phải)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: _viewMode == DetailViewMode.overview
                        ? Colors.transparent
                        : const Color(0xFF0F1014).withValues(alpha: 0.90),
                    gradient: _viewMode == DetailViewMode.overview
                        ? const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xF60F1014), // 96% ở mép trái
                              Color(0xEE0F1014), // 93% dưới cột trái
                              Color(0xBD0F1014), // 74% ở giữa (backdrop nhân vật hiện rõ nét nhưng dịu mắt)
                              Color(0xCC0F1014), // 80% chuyển sang cột phải
                              Color(0xDE0F1014), // 87% ở mép phải (nền tối êm dịu cho danh sách tập)
                            ],
                            stops: [0.0, 0.35, 0.52, 0.75, 1.0],
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // 3. Lớp LinearGradient dọc mờ nhẹ từ đỉnh và đáy (Vignette cinematic)
            if (_viewMode == DetailViewMode.overview)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x800F1014), // Mờ nhẹ ở đỉnh (50%)
                          Colors.transparent,
                          Color(0xB30F1014), // Mờ nhẹ ở đáy (70%)
                        ],
                        stops: [0.0, 0.25, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

            // 4. Lớp chứa nội dung chữ và nút bấm (Nằm trên cùng)
            SafeArea(
              child: Column(
                children: [
                  _buildTopNavBar(context),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildCurrentStateView(movie, movieItem, episodes, progress),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh điều hướng trên cùng: chỉ giữ lại nút tròn ← ở góc trên bên trái
  Widget _buildTopNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 10, 32, 4),
      child: Row(
        children: [
          // Bên trái: Nút tròn ← (thoát trang hoặc quay lại tổng quan)
          TVFocusable(
            onPressed: () {
              if (_viewMode != DetailViewMode.overview) {
                setState(() => _viewMode = DetailViewMode.overview);
              } else {
                Navigator.pop(context);
              }
            },
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            ),
          ),

          // Ở Trạng thái 2 & 3: Thêm khoảng cách 12px và chữ "Quay lại tổng quan"
          if (_viewMode != DetailViewMode.overview) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _viewMode = DetailViewMode.overview),
              child: const Text(
                'Quay lại tổng quan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStateView(
    MovieDetail movie,
    MovieItem movieItem,
    List<EpisodeItem> episodes,
    WatchProgress? progress,
  ) {
    switch (_viewMode) {
      case DetailViewMode.overview:
        return _buildOverviewView(movie, movieItem, episodes, progress);
      case DetailViewMode.episodes:
        return _buildEpisodesView(movie, episodes, progress);
      case DetailViewMode.similar:
        return _buildSimilarView(movie);
    }
  }

  /// Trạng thái 1 — Màn hình Chi tiết tổng quan (Hero Backdrop tràn viền)
  /// Trạng thái 1 — Màn hình Chi tiết tổng quan chuẩn Netflix TV
  Widget _buildOverviewView(
    MovieDetail movie,
    MovieItem movieItem,
    List<EpisodeItem> episodes,
    WatchProgress? progress,
  ) {
    final resumeEp = progress != null && progress.episodeSlug.isNotEmpty
        ? episodes.firstWhere((e) => e.slug == progress.episodeSlug, orElse: () => episodes.first)
        : (episodes.isNotEmpty ? episodes.first : null);

    // Logic phim lẻ vs phim bộ:
    // Phim lẻ: khi movie.type == 'single' hoặc tất cả các server đều chỉ có <= 1 tập (ví dụ Tập Full).
    // Phim bộ: chỉ khi có ít nhất 1 server có từ 2 tập trở lên.
    final maxEpisodesAcrossServers = movie.episodes.fold<int>(
      0,
      (max, s) => s.serverData.length > max ? s.serverData.length : max,
    );
    final isSingleEpisodeMovie = movie.type == 'single' || maxEpisodesAcrossServers <= 1;

    // Cắt bỏ phần tên phụ sau dấu / ở tiêu đề chính
    final mainTitle = movie.name.split('/').first.trim();

    // Nhãn nút phát chuẩn xác: luôn hiển thị đúng tập đang xem dở
    final playLabel = episodes.isEmpty
        ? 'Chưa có nguồn phát'
        : (progress != null && resumeEp != null
            ? (progress.positionSeconds > 10
                ? 'Tiếp tục ${resumeEp.name}'
                : 'Xem ${resumeEp.name}')
            : 'Xem ${episodes.first.name}');

    final overviewLeft = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Clear Logo Art hoặc Tiêu đề phim
            if (movie.clearLogoUrl != null && movie.clearLogoUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 76, maxWidth: 340),
                  child: CachedPosterImage(
                    imageUrl: movie.clearLogoUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else ...[
              Text(
                mainTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              if (movie.originName.isNotEmpty && movie.originName != mainTitle) ...[
                const SizedBox(height: 4),
                Text(
                  movie.originName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 10),
            ],

            // 2. Metadata badges (Năm, Chất lượng, Ngôn ngữ, Thời lượng, Điểm, Nhà mạng/Hãng phim)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (movie.year > 0)
                  Text(
                    '${movie.year}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    border: Border.all(color: Colors.white30, width: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    movie.quality.isNotEmpty ? movie.quality : 'FHD',
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
                if (movie.lang.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      movie.lang,
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (movie.time.isNotEmpty)
                  Text(
                    movie.time,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                if (movie.voteAverage > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.star, size: 15),
                      const SizedBox(width: 3),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                if (movie.networks.isNotEmpty)
                  ...movie.networks.take(2).map((n) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Text(
                          n.name,
                          style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ))
                else if (movie.productionCompanies.isNotEmpty)
                  ...movie.productionCompanies.take(1).map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Text(
                          c.name,
                          style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      )),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Tóm tắt 3 dòng
            Text(
              movie.content.isNotEmpty
                  ? _cleanContent(movie.content)
                  : 'Chưa có tóm tắt cho phim này.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 10),

            // 4. Diễn viên & Đạo diễn
            if (movie.actors.isNotEmpty && movie.actors.first.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12.5),
                    children: [
                      const TextSpan(text: 'Diễn viên: ', style: TextStyle(color: AppColors.textMuted)),
                      TextSpan(
                        text: movie.actors.take(5).join(', '),
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            if (movie.directors.isNotEmpty && movie.directors.first.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12.5),
                    children: [
                      const TextSpan(text: 'Đạo diễn: ', style: TextStyle(color: AppColors.textMuted)),
                      TextSpan(
                        text: movie.directors.join(', '),
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Chọn Server phát cho phim lẻ nếu có nhiều bản
            if (isSingleEpisodeMovie && movie.episodes.length > 1) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: List.generate(movie.episodes.length, (sIdx) {
                  final isServerSelected = _selectedServerIndex == sIdx;
                  return TVFocusable(
                    showBorder: false,
                    onPressed: () {
                      setState(() {
                        _selectedServerIndex = sIdx;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isServerSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isServerSelected ? AppColors.primary : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        movie.episodes[sIdx].serverName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: isServerSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],

            // 5. Nút CTA chính (Đỏ Movix)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: _buildPrimaryPlayButton(
                label: playLabel,
                available: episodes.isNotEmpty,
                onTap: () {
                  if (episodes.isNotEmpty && resumeEp != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          movie: movie,
                          episode: resumeEp,
                          allEpisodes: episodes,
                          initialPositionSeconds: progress?.positionSeconds ?? 0,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) setState(() {});
                    });
                  } else {
                    AppToast.show(context, 'Phim hiện chưa có nguồn phát trực tuyến', icon: Icons.info_outline_rounded);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),

            // 6. Hàng nút hành động phụ: Nút tròn Lưu/Thích/Chia sẻ + Tương tự/Bình luận
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ValueListenableBuilder<List<MovieItem>>(
                  valueListenable: _userStorage.myListNotifier,
                  builder: (context, _, __) {
                    final inList = _userStorage.isInMyList(movie.slug, tmdbId: movie.tmdbId);
                    return _buildCircleActionButton(
                      icon: inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      tooltip: inList ? 'Đã lưu' : 'Lưu phim',
                      color: inList ? AppColors.primary : Colors.white,
                      onTap: () => _userStorage.toggleMyList(movieItem),
                    );
                  },
                ),
                _buildCircleActionButton(
                  icon: _isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                  tooltip: 'Thích',
                  color: _isLiked ? AppColors.primary : Colors.white,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isLiked = !_isLiked);
                  },
                ),
                _buildCircleActionButton(
                  icon: Icons.share_outlined,
                  tooltip: 'Chia sẻ',
                  onTap: () => AppToast.show(context, 'Đã sao chép liên kết phim', icon: Icons.link_rounded),
                ),
                if (!isSingleEpisodeMovie)
                  _buildSecondaryActionButton(
                    icon: Icons.grid_view_rounded,
                    label: 'Tương tự',
                    onTap: () => setState(() => _viewMode = DetailViewMode.similar),
                  ),
                _buildSecondaryActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Bình luận',
                  onTap: () => _showCommentsModal(context, movie),
                ),
              ],
            ),

            // 7. Diễn viên & Vai diễn
            if (movie.tmdbCast.isNotEmpty || movie.actors.isNotEmpty) ...[
              const SizedBox(height: 18),
              CastListWidget(
                tmdbCast: movie.tmdbCast,
                fallbackActors: movie.actors,
              ),
            ],

            // 8. Trọn bộ sưu tập (cho phim bộ nếu có)
            if (!isSingleEpisodeMovie && movie.collectionId != null)
              CollectionWidget(
                collectionId: movie.collectionId!,
                collectionName: movie.collectionName ?? '',
                currentMovieSlug: movie.slug,
                currentTmdbId: movie.tmdbId,
              ),
          ],
        ),
      ),
    );

    // Nếu phim chỉ có 1 tập (phim lẻ): bố cục 2 cột (Thông tin trái 48%, Đề xuất/Bộ sưu tập phải 52%)
    if (isSingleEpisodeMovie) {
      return Padding(
        padding: const EdgeInsets.only(left: 36, right: 28, bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 48,
              child: Center(child: overviewLeft),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 52,
              child: _buildSingleMovieRightPanel(movie),
            ),
          ],
        ),
      );
    }

    // Nếu phim có nhiều tập: bố cục 2 cột (Thông tin trái 46%, Danh sách tập phải 54%)
    return Padding(
      padding: const EdgeInsets.only(left: 36, right: 28, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 46,
            child: Center(child: overviewLeft),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 54,
            child: _buildNetflixEpisodeList(movie, episodes, progress),
          ),
        ],
      ),
    );
  }

  /// Cột bên phải dành riêng cho Phim lẻ:
  /// 1. Trọn bộ sưu tập (nếu có)
  /// 2. Lưới 3 cột Phim tương tự & Đề xuất (TMDb Smart Match)
  Widget _buildSingleMovieRightPanel(MovieDetail movie) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (movie.collectionId != null) ...[
            CollectionWidget(
              collectionId: movie.collectionId!,
              collectionName: movie.collectionName ?? '',
              currentMovieSlug: movie.slug,
              currentTmdbId: movie.tmdbId,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLight, size: 16),
              const SizedBox(width: 6),
              Text('Phim tương tự & Đề xuất', style: AppTypography.titleMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primaryBorder, width: 0.8),
                ),
                child: Text(
                  'TMDb Smart Match',
                  style: AppTypography.badge.copyWith(color: AppColors.primaryLight, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final similarAsync = ref.watch(similarMoviesProvider(movie));
                return similarAsync.when(
                  data: (movies) {
                    final filtered = movies.where((m) => m.slug != movie.slug).toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'Đang cập nhật đề xuất phù hợp...',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      );
                    }
                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.60,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        return TVFocusable(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovieDetailScreen(
                                  slug: item.slug,
                                  tmdbId: item.tmdbId,
                                  tmdbMediaType: item.tmdbMediaType,
                                  previewMovie: item,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedPosterImage(
                                    imageUrl: item.fullPosterUrl,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 260,
                                    memCacheHeight: 390,
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.85),
                                          ],
                                          stops: const [0.55, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (item.quality.isNotEmpty)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.72),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.quality,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    left: 8,
                                    right: 8,
                                    bottom: 8,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.bodySmall.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                          ),
                                        ),
                                        if (item.year > 0)
                                          Text(
                                            '${item.year}',
                                            style: AppTypography.labelSmall.copyWith(
                                              color: AppColors.textMuted,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const PosterGridSkeleton(
                    itemCount: 6,
                    crossAxisCount: 3,
                    childAspectRatio: 0.60,
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Danh sách tập bên phải chuẩn Apple TV / Netflix:
  /// - Được đặt trong Side Panel tối mờ (Frosted Dark Glass) đồng bộ tự nhiên với nền
  /// - Hỗ trợ chuyển đổi linh hoạt: Lưới số tập (Grid Badges) và Thẻ chi tiết (Cards)
  /// - Phân đoạn thông minh: Tự động chia nhóm 50 tập/tab (hoặc 25) giúp thao tác nhanh
  Widget _buildNetflixEpisodeList(
    MovieDetail movie,
    List<EpisodeItem> episodes,
    WatchProgress? progress,
  ) {
    if (episodes.isEmpty) return const SizedBox.shrink();

    final isGrid = _userSetEpisodeGridMode ?? (episodes.length > 30);

    final chunkSize = isGrid
        ? (episodes.length > 100 ? 50 : 25)
        : 20;

    final totalChunks = (episodes.length / chunkSize).ceil();
    final currentChunk = _selectedChunkIndex.clamp(0, totalChunks > 0 ? totalChunks - 1 : 0);
    final startIndex = currentChunk * chunkSize;
    final endIndex = (startIndex + chunkSize).clamp(0, episodes.length);
    final displayedEpisodes = episodes.isNotEmpty ? episodes.sublist(startIndex, endIndex) : <EpisodeItem>[];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tiêu đề + Server + Nút chuyển chế độ xem (Lưới số vs Thẻ)
          Row(
            children: [
              const Text(
                'Danh sách tập',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${episodes.length} tập',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),

              // Chọn Server phát (nếu có từ 2 server trở lên)
              if (movie.episodes.length > 1) ...[
                ...List.generate(movie.episodes.length, (sIdx) {
                  final isServerSelected = _selectedServerIndex == sIdx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TVFocusable(
                      showBorder: false,
                      onPressed: () {
                        setState(() {
                          _selectedServerIndex = sIdx;
                          _selectedChunkIndex = 0;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isServerSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isServerSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.12),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          movie.episodes[sIdx].serverName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isServerSelected ? FontWeight.bold : FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],

              // Nút Toggle chuyển đổi giữa Lưới số tập và Thẻ chi tiết
              Tooltip(
                message: isGrid ? 'Chuyển sang dạng Thẻ chi tiết' : 'Chuyển sang dạng Lưới số tập',
                child: TVFocusable(
                  showBorder: false,
                  onPressed: () {
                    setState(() {
                      _userSetEpisodeGridMode = !isGrid;
                      _selectedChunkIndex = 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGrid ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isGrid ? 'Thẻ' : 'Số',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Thanh phân đoạn khoảng tập (Tập 1 - 50, Tập 51 - 100...)
          if (totalChunks > 1) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(totalChunks, (c) {
                  final isChunkSelected = c == currentChunk;
                  final cStart = c * chunkSize + 1;
                  final cEnd = ((c + 1) * chunkSize).clamp(1, episodes.length);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TVFocusable(
                      showBorder: false,
                      onPressed: () => setState(() => _selectedChunkIndex = c),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: isChunkSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isChunkSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.10),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Tập $cStart - $cEnd',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isChunkSelected ? FontWeight.bold : FontWeight.w500,
                            color: isChunkSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Body: Lưới số tập (Chế độ A) hoặc Thẻ chi tiết (Chế độ B)
          Expanded(
            child: isGrid
                ? _buildNumberGridEpisodes(
                    displayedEpisodes: displayedEpisodes,
                    startIndex: startIndex,
                    movie: movie,
                    episodes: episodes,
                    progress: progress,
                  )
                : _buildCardEpisodes(
                    displayedEpisodes: displayedEpisodes,
                    startIndex: startIndex,
                    movie: movie,
                    episodes: episodes,
                    progress: progress,
                  ),
          ),
        ],
      ),
    );
  }

  /// Chế độ Lưới số tập (Grid Badges) - Chuyên nghiệp cho anime & phim bộ dài
  Widget _buildNumberGridEpisodes({
    required List<EpisodeItem> displayedEpisodes,
    required int startIndex,
    required MovieDetail movie,
    required List<EpisodeItem> episodes,
    required WatchProgress? progress,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 540 ? 6 : 5;
        return GridView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.55,
          ),
          itemCount: displayedEpisodes.length,
          itemBuilder: (context, idx) {
            final ep = displayedEpisodes[idx];
            final globalIdx = startIndex + idx;
            final isPlayingThis = progress != null && progress.episodeSlug == ep.slug;
            final cleanName = ep.name.trim();
            final epText = cleanName.toLowerCase().startsWith('tập') ? cleanName : 'Tập $cleanName';
            final isFocused = _focusedEpisodeIndex == globalIdx;

            return MouseRegion(
              onEnter: (_) {
                if (_focusedEpisodeIndex != globalIdx) {
                  setState(() => _focusedEpisodeIndex = globalIdx);
                }
              },
              child: TVFocusable(
                showBorder: false,
                scale: 1.04,
                onFocusChange: (focused) {
                  if (focused && _focusedEpisodeIndex != globalIdx) {
                    setState(() => _focusedEpisodeIndex = globalIdx);
                  }
                },
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(
                        movie: movie,
                        episode: ep,
                        allEpisodes: episodes,
                        initialPositionSeconds: isPlayingThis ? progress.positionSeconds : 0,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isPlayingThis
                        ? AppColors.primary
                        : (isFocused ? Colors.white.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.07)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPlayingThis
                          ? AppColors.primary
                          : (isFocused ? Colors.white : Colors.white.withValues(alpha: 0.10)),
                      width: isFocused || isPlayingThis ? 1.5 : 0.8,
                    ),
                    boxShadow: (isFocused || isPlayingThis)
                        ? [
                            BoxShadow(
                              color: isPlayingThis
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPlayingThis) ...[
                            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 2),
                          ],
                          Flexible(
                            child: Text(
                              epText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isPlayingThis || isFocused ? FontWeight.bold : FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isPlayingThis && progress.durationSeconds > 0)
                        Positioned(
                          bottom: 0,
                          left: 4,
                          right: 4,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                            child: LinearProgressIndicator(
                              value: (progress.positionSeconds / progress.durationSeconds).clamp(0.0, 1.0),
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 2.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Chế độ Thẻ chi tiết 2 cột (Compact Cards)
  Widget _buildCardEpisodes({
    required List<EpisodeItem> displayedEpisodes,
    required int startIndex,
    required MovieDetail movie,
    required List<EpisodeItem> episodes,
    required WatchProgress? progress,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMultiCol = constraints.maxWidth >= 460 && displayedEpisodes.length > 4;
        final crossAxisCount = isMultiCol ? 2 : 1;
        final rowCount = (displayedEpisodes.length / crossAxisCount).ceil();

        return ListView.separated(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: rowCount,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, rowIndex) {
            if (crossAxisCount == 1) {
              final ep = displayedEpisodes[rowIndex];
              return _buildCompactEpisodeCard(
                ep: ep,
                globalIndex: startIndex + rowIndex,
                movie: movie,
                episodes: episodes,
                progress: progress,
                isWide: false,
              );
            }
            final idx1 = rowIndex * 2;
            final idx2 = idx1 + 1;
            return Row(
              children: [
                Expanded(
                  child: _buildCompactEpisodeCard(
                    ep: displayedEpisodes[idx1],
                    globalIndex: startIndex + idx1,
                    movie: movie,
                    episodes: episodes,
                    progress: progress,
                    isWide: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: idx2 < displayedEpisodes.length
                      ? _buildCompactEpisodeCard(
                          ep: displayedEpisodes[idx2],
                          globalIndex: startIndex + idx2,
                          movie: movie,
                          episodes: episodes,
                          progress: progress,
                          isWide: true,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Thẻ tập thu gọn chuẩn Netflix: 16:9 thumbnail + Tên tập + Thời lượng
  Widget _buildCompactEpisodeCard({
    required EpisodeItem ep,
    required int globalIndex,
    required MovieDetail movie,
    required List<EpisodeItem> episodes,
    required WatchProgress? progress,
    required bool isWide,
  }) {
    final isPlayingThis = progress != null && progress.episodeSlug == ep.slug;
    final cleanName = ep.name.trim();
    final epNum = cleanName.replaceAll(RegExp(r'[^0-9]'), '');
    final epTitle = cleanName.toLowerCase().startsWith('tập') ? cleanName : 'Tập $cleanName';
    final duration = movie.time.isNotEmpty ? movie.time : '45 phút';
    final isFocused = _focusedEpisodeIndex == globalIndex;

    return MouseRegion(
      onEnter: (_) {
        if (_focusedEpisodeIndex != globalIndex) {
          setState(() => _focusedEpisodeIndex = globalIndex);
        }
      },
      child: TVFocusable(
        showBorder: false,
        scale: 1.02,
        onFocusChange: (focused) {
          if (focused && _focusedEpisodeIndex != globalIndex) {
            setState(() => _focusedEpisodeIndex = globalIndex);
          }
        },
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(
                movie: movie,
                episode: ep,
                allEpisodes: episodes,
                initialPositionSeconds: isPlayingThis ? progress.positionSeconds : 0,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: isWide ? 66 : 74,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isPlayingThis
                ? AppColors.primary.withValues(alpha: 0.18)
                : (isFocused
                    ? Colors.white.withValues(alpha: 0.14)
                    : const Color(0xFF1E2028).withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPlayingThis
                  ? AppColors.primary
                  : (isFocused ? Colors.white : Colors.white.withValues(alpha: 0.08)),
              width: isFocused || isPlayingThis ? 1.5 : 1.0,
            ),
            boxShadow: isPlayingThis
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : (isFocused
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : []),
          ),
          child: Row(
            children: [
              // 1. Thumbnail 16:9 với badge "Tập X"
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedPosterImage(
                        imageUrl: movie.backdropUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xB3000000)],
                            stops: [0.3, 1.0],
                          ),
                        ),
                      ),
                      if (isFocused)
                        const Center(
                          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                        ),
                      Positioned(
                        left: 5,
                        bottom: 3,
                        child: Text(
                          epNum.isNotEmpty ? 'Tập $epNum' : cleanName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 2. Tiêu đề tập & Thông tin gọn gàng (Không có miêu tả lặp lại vô nghĩa)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      epTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isWide ? 13.5 : 15,
                        fontWeight: FontWeight.bold,
                        color: isFocused ? Colors.white : const Color(0xFFEEEEEE),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          duration,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        if (isPlayingThis) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'ĐANG XEM',
                              style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Trạng thái 2 — Chế độ Danh sách tập (Episodes View: 35% Trái / 65% Phải)
  Widget _buildEpisodesView(
    MovieDetail movie,
    List<EpisodeItem> episodes,
    WatchProgress? progress,
  ) {
    const chunkSize = 40;
    final totalChunks = (episodes.length / chunkSize).ceil();
    final currentChunk = _selectedChunkIndex.clamp(0, totalChunks > 0 ? totalChunks - 1 : 0);
    final startIndex = currentChunk * chunkSize;
    final endIndex = (startIndex + chunkSize).clamp(0, episodes.length);
    final displayedEpisodes = episodes.isNotEmpty ? episodes.sublist(startIndex, endIndex) : <EpisodeItem>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 10, 36, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột trái (35%): Thông tin phim, Server, Khoảng tập
          Expanded(
            flex: 35,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đang chiếu: ${movie.episodeCurrent} • ${movie.time}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  if (movie.episodes.length > 1) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'Máy chủ phát:',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(movie.episodes.length, (idx) {
                      return _buildServerSelectTile(
                        movie.episodes[idx].serverName,
                        idx == _selectedServerIndex,
                        () {
                          setState(() {
                            _selectedServerIndex = idx;
                            _selectedChunkIndex = 0;
                          });
                        },
                      );
                    }),
                  ],
                  if (totalChunks > 1) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Khoảng tập:',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(totalChunks, (c) {
                      final s = c * chunkSize + 1;
                      final e = ((c + 1) * chunkSize).clamp(0, episodes.length);
                      return _buildServerSelectTile(
                        'Tập $s - $e',
                        c == currentChunk,
                        () => setState(() => _selectedChunkIndex = c),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 32),

          // Cột phải (65%): Lưới các nút tập 4 cột rộng rãi (#1E2028, bo góc 10px)
          Expanded(
            flex: 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danh sách tập (${displayedEpisodes.length}/${episodes.length} tập)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: displayedEpisodes.isEmpty
                      ? const Center(
                          child: Text('Không có tập phim nào.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      : GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisExtent: 44,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: displayedEpisodes.length,
                          itemBuilder: (context, idx) {
                            final ep = displayedEpisodes[idx];
                            final isPlayingThis = progress?.episodeSlug == ep.slug;

                            return TVFocusable(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerScreen(
                                      movie: movie,
                                      episode: ep,
                                      allEpisodes: episodes,
                                      initialPositionSeconds: isPlayingThis ? (progress?.positionSeconds ?? 0) : 0,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isPlayingThis
                                      ? AppColors.primary
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isPlayingThis
                                        ? AppColors.primary
                                        : AppColors.borderLight,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  ep.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isPlayingThis ? AppColors.textPrimary : AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: isPlayingThis ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Trạng thái 3 — Chế độ Phim tương tự (More Like This View: Lưới 5 cột)
  Widget _buildSimilarView(MovieDetail movie) {
    final similarAsync = ref.watch(similarMoviesProvider(movie));

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 10, 36, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trọn bộ sưu tập / Franchise (Feature 3)
          if (movie.collectionId != null) ...[
            CollectionWidget(
              collectionId: movie.collectionId!,
              collectionName: movie.collectionName ?? '',
              currentMovieSlug: movie.slug,
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              const Text(
                'Phim tương tự & Đề xuất',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primaryBorder, width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLight, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'TMDb Smart Match',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lưới 5 cột các thẻ Poster phim
          Expanded(
            child: similarAsync.when(
              data: (movies) {
                final filtered = movies.where((m) => m.slug != movie.slug).toList();
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Không có phim tương tự.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final item = filtered[idx];
                    return TVFocusable(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(
                              slug: item.slug,
                              tmdbId: item.tmdbId,
                              tmdbMediaType: item.tmdbMediaType,
                              previewMovie: item,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedPosterImage(
                                    imageUrl: item.fullPosterUrl,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: RatingBadge(
                                      rating: item.quality.isNotEmpty ? item.quality : 'FHD',
                                      isRed: true,
                                    ),
                                  ),
                                  if (item.year > 0)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: RatingBadge(
                                        rating: '${item.year}',
                                        isRed: false,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.episodeCurrent.isNotEmpty ? item.episodeCurrent : '${item.year}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const PosterGridSkeleton(
                crossAxisCount: 5,
                itemCount: 10,
                childAspectRatio: 0.58,
              ),
              error: (_, __) => const Center(
                child: Text('Không thể tải phim tương tự.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentsModal(BuildContext context, MovieDetail movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        int activeTab = 0;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Segmented Tabs (Movix comments vs TMDb international reviews)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setModalState(() => activeTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: activeTab == 0 ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: activeTab == 0 ? AppColors.primary : Colors.white12,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'Bình luận Movix',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: activeTab == 0 ? FontWeight.bold : FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setModalState(() => activeTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: activeTab == 1 ? AppColors.primary : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: activeTab == 1 ? AppColors.primary : AppColors.borderSubtle,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: activeTab == 1 ? Colors.white : AppColors.star,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Đánh giá quốc tế (TMDb)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: activeTab == 1 ? FontWeight.bold : FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),
                  Expanded(
                    child: activeTab == 0
                        ? MovieCommentsWidget(movieSlug: movie.slug)
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: MovieReviewsWidget(movie: movie),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Nút hành động trên màn hình mobile dọc (Danh sách, Thích, Chia sẻ)
  Widget _buildMobileActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopIconSwitch(
              child: Icon(icon, key: ValueKey(icon), color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color == AppColors.primary ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nút phát chính (Play Button) rực rỡ, bề thế chuẩn Apple TV
  Widget _buildPrimaryPlayButton({
    required String label,
    required VoidCallback onTap,
    bool available = true,
  }) {
    return TVFocusable(
      autoFocus: true,
      showBorder: false,
      scale: 1.02,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: available ? AppColors.primary : const Color(0xFF282B34),
          borderRadius: BorderRadius.circular(10),
          border: available ? null : Border.all(color: Colors.white24, width: 1),
          boxShadow: available
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              available ? Icons.play_arrow_rounded : Icons.schedule_rounded,
              color: available ? Colors.white : Colors.white70,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: available ? Colors.white : Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? Colors.white;
    return Tooltip(
      message: tooltip,
      child: TVFocusable(
        showBorder: false,
        scale: 1.05,
        onPressed: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(
              color: color == AppColors.primary ? AppColors.primary : Colors.white30,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: PopIconSwitch(
            child: Icon(icon, key: ValueKey(icon), color: activeColor, size: 17),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? Colors.white;
    return TVFocusable(
      showBorder: false,
      scale: 1.03,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color == AppColors.primary ? AppColors.primary : Colors.white30,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopIconSwitch(
              child: Icon(icon, key: ValueKey(icon), color: activeColor, size: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: activeColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildServerSelectTile(String title, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TVFocusable(
        onPressed: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.18)
                : const Color(0xFF1E2028),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cleanContent(String content) {
    return content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();
  }
}
