import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/models/movie_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/movie_providers.dart';
import '../../widgets/cached_poster_image.dart';
import '../../widgets/episode_grid_widget.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/tv_focusable.dart';
import '../player/player_screen.dart';
import 'widgets/movie_comments_widget.dart';

enum DetailViewMode {
  overview,
  episodes,
  similar,
}

class MovieDetailScreen extends ConsumerStatefulWidget {
  final String slug;

  const MovieDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  final UserStorage _userStorage = UserStorage();
  int _selectedServerIndex = 0;
  int _selectedChunkIndex = 0;
  bool _isDescriptionExpanded = false;
  DetailViewMode _viewMode = DetailViewMode.overview;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(movieDetailProvider(widget.slug));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        data: (movie) => _buildContent(movie),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Text(
              'Lỗi tải thông tin phim: $err',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
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
    );

    final episodes = movie.episodes.isNotEmpty
        ? (_selectedServerIndex < movie.episodes.length
            ? movie.episodes[_selectedServerIndex].serverData
            : movie.episodes.first.serverData)
        : <EpisodeItem>[];

    // Check watch progress to resume
    final progress = _userStorage.getProgress(movie.slug);

    final isTabletLandscape = MediaQuery.of(context).size.width >= 600;
    if (isTabletLandscape) {
      return _buildTabletLandscapeContent(movie, movieItem, episodes, progress);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        return ref.refresh(movieDetailProvider(widget.slug).future);
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
                final inList = _userStorage.isInMyList(movie.slug);
                return IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: inList ? AppColors.primary : Colors.white,
                      size: 20,
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
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedPosterImage(
                  imageUrl: movie.fullPosterUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 720,
                  memCacheHeight: 960,
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.heroGradient,
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
                // Title
                Text(
                  movie.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                if (movie.originName.isNotEmpty && movie.originName != movie.name) ...[
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

                // Metadata Badges (Rating, Year, Quality, Time)
                Row(
                  children: [
                    const RatingBadge(rating: '9.8', isRed: true),
                    const SizedBox(width: 8),
                    RatingBadge(rating: '${movie.year}', isRed: false),
                    const SizedBox(width: 8),
                    RatingBadge(rating: movie.quality, isRed: false),
                    const SizedBox(width: 8),
                    if (movie.time.isNotEmpty)
                      Text(
                        movie.time,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 20),

                // Main Play / Resume Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
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
                        );
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    label: Text(
                      progress != null && progress.positionSeconds > 10
                          ? 'Tiếp tục xem: ${progress.episodeName}'
                          : 'Xem Phim Ngay',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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

                // Diễn viên
                if (movie.actors.isNotEmpty) ...[
                  const Text(
                    'Diễn viên',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.actors.join(', '),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
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

                // Comments & Reviews Section
                const SizedBox(height: 28),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bình luận & Đánh giá',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '142 bình luận',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                MovieCommentsWidget(movieSlug: movie.slug),

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
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Hero Backdrop tràn viền toàn màn hình
            Positioned.fill(
              child: CachedPosterImage(
                imageUrl: movie.fullThumbUrl.isNotEmpty ? movie.fullThumbUrl : movie.fullPosterUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // 2. Lớp gradient tối dần từ trái sang phải và mờ dần xuống đáy
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: _viewMode == DetailViewMode.overview
                      ? Colors.transparent
                      : Colors.black.withValues(alpha: 0.88),
                  gradient: _viewMode == DetailViewMode.overview
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xF20A0B0E), // Đen mờ 95% bên trái
                            Color(0xD90A0B0E), // Đen mờ 85%
                            Color(0x660A0B0E), // Trong suốt 40%
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.44, 0.72, 1.0],
                        )
                      : null,
                ),
              ),
            ),

            // Lớp gradient mờ dần xuống đáy ở chế độ Tổng quan
            if (_viewMode == DetailViewMode.overview)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x800A0B0E),
                        Colors.transparent,
                        Color(0xF50A0B0E),
                      ],
                      stops: [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
              ),

            // 3. Nội dung 3 trạng thái chuyển đổi mượt mà
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentStateView(movie, movieItem, episodes, progress),
              ),
            ),

            // 4. Nút Quay lại (<) nổi góc trên bên trái (nền tròn kính mờ)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              child: TVFocusable(
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
            ),

            // 5. Nút Lưu (Bookmark) và Chia sẻ (Share) góc trên bên phải (nền tròn kính mờ)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: Row(
                children: [
                  ValueListenableBuilder<List<MovieItem>>(
                    valueListenable: _userStorage.myListNotifier,
                    builder: (context, _, __) {
                      final inList = _userStorage.isInMyList(movie.slug);
                      return TVFocusable(
                        onPressed: () => _userStorage.toggleMyList(movieItem),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Icon(
                            inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: inList ? AppColors.primary : Colors.white,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  TVFocusable(
                    onPressed: () {
                      AppToast.show(context, 'Đã sao chép liên kết phim', icon: Icons.link_rounded);
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: const Icon(Icons.share_outlined, color: Colors.white, size: 22),
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
  Widget _buildOverviewView(
    MovieDetail movie,
    MovieItem movieItem,
    List<EpisodeItem> episodes,
    WatchProgress? progress,
  ) {
    final width = MediaQuery.of(context).size.width;
    final resumeEp = progress != null && progress.episodeSlug.isNotEmpty
        ? episodes.firstWhere((e) => e.slug == progress.episodeSlug, orElse: () => episodes.first)
        : (episodes.isNotEmpty ? episodes.first : null);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 36, top: 40, bottom: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width * 0.48),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tên phim chính
                Text(
                  movie.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                  ),
                ),
                if (movie.originName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    movie.originName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // Hàng metadata: Điểm đánh giá, Năm, FHD, Vietsub, Thể loại
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const RatingBadge(
                      rating: '9.8',
                      isRed: true,
                    ),
                    Text(
                      '${movie.year}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    _buildMetaChip(movie.quality.isNotEmpty ? movie.quality : 'FHD', isPrimary: true),
                    _buildMetaChip(movie.lang.isNotEmpty ? movie.lang : 'Vietsub'),
                    if (movie.categories.isNotEmpty)
                      Text(
                        movie.categories.map((c) => c.name).take(3).join(', '),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tóm tắt nội dung giới hạn tối đa 3 dòng
                Text(
                  movie.content.isNotEmpty ? _cleanContent(movie.content) : 'Chưa có tóm tắt cho phim này.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.45,
                  ),
                ),

                // Dòng Diễn viên (1 dòng)
                if (movie.actors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Diễn viên: ${movie.actors.join(", ")}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 22),

                // Nút chính nổi bật: ▶ Xem Tập 01 hoặc ▶ Tiếp tục Tập XX
                TVFocusable(
                  onPressed: () {
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
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE50914).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          progress != null && progress.positionSeconds > 10
                              ? 'Tiếp tục ${progress.episodeName.isNotEmpty ? progress.episodeName : "Tập ${progress.episodeSlug}"}'
                              : (episodes.isNotEmpty ? 'Xem ${episodes.first.name}' : 'Xem Phim'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Các lựa chọn phụ bên dưới dạng hàng menu tối giản (icon + chữ)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuItem(
                      icon: Icons.video_library_outlined,
                      label: 'Danh sách tập',
                      onTap: () => setState(() => _viewMode = DetailViewMode.episodes),
                    ),
                    const SizedBox(width: 14),
                    _buildMenuItem(
                      icon: Icons.auto_awesome_motion_outlined,
                      label: 'Phim tương tự',
                      onTap: () => setState(() => _viewMode = DetailViewMode.similar),
                    ),
                    const SizedBox(width: 14),
                    _buildMenuItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Bình luận',
                      onTap: () => _showCommentsModal(context, movie.slug),
                    ),
                  ],
                ),
              ],
            ),
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
      padding: const EdgeInsets.fromLTRB(36, 40, 36, 24),
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
                  TVFocusable(
                    onPressed: () => setState(() => _viewMode = DetailViewMode.overview),
                    borderRadius: BorderRadius.circular(8),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Quay lại tổng quan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Danh sách tập (${displayedEpisodes.length}/${episodes.length} tập)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    if (progress != null && progress.episodeSlug.isNotEmpty)
                      Text(
                        'Đang xem: ${progress.episodeName}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                  ],
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
                                      ? const Color(0xFFE50914)
                                      : const Color(0xFF1E2028),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isPlayingThis
                                        ? const Color(0xFFE50914)
                                        : const Color(0xFF2E313C),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  ep.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isPlayingThis ? Colors.white : Colors.white70,
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
    final firstCatSlug = movie.categories.isNotEmpty ? movie.categories.first.slug : 'hanh-dong';
    final firstCatName = movie.categories.isNotEmpty ? movie.categories.first.name : 'Phim Đề Xuất';
    final similarAsync = ref.watch(similarMoviesProvider(firstCatSlug));

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 40, 36, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nút quay lại + Tiêu đề
          Row(
            children: [
              TVFocusable(
                onPressed: () => setState(() => _viewMode = DetailViewMode.overview),
                borderRadius: BorderRadius.circular(8),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text('Quay lại tổng quan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Text(
                'Phim tương tự: $firstCatName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),

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
                            builder: (context) => MovieDetailScreen(slug: item.slug),
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
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
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

  void _showCommentsModal(BuildContext context, String movieSlug) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
              const Text(
                'Bình luận & Đánh giá',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: MovieCommentsWidget(movieSlug: movieSlug),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaChip(String label, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPrimary ? AppColors.primary : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPrimary ? AppColors.primary : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TVFocusable(
      onPressed: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
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
