import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/models/movie_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/movie_providers.dart';
import '../../widgets/cached_poster_image.dart';
import '../../widgets/episode_grid_widget.dart';
import '../../widgets/rating_badge.dart';
import '../player/player_screen.dart';
import 'widgets/movie_comments_widget.dart';

class MovieDetailScreen extends ConsumerStatefulWidget {
  final String slug;

  const MovieDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  final UserStorage _userStorage = UserStorage();
  int _selectedServerIndex = 0;
  bool _isDescriptionExpanded = false;

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

    final isTabletLandscape = MediaQuery.of(context).size.width >= 800;
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép liên kết phim')),
                );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(movie.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          ValueListenableBuilder<List<MovieItem>>(
            valueListenable: _userStorage.myListNotifier,
            builder: (context, _, __) {
              final inList = _userStorage.isInMyList(movie.slug);
              return IconButton(
                icon: Icon(
                  inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: inList ? AppColors.primary : Colors.white,
                ),
                onPressed: () => _userStorage.toggleMyList(movieItem),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép liên kết phim')),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column (Movie Info, Poster, Play button)
          Expanded(
            flex: 48,
            child: ListView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedPosterImage(
                      imageUrl: movie.fullPosterUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  movie.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (movie.originName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    movie.originName,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const RatingBadge(rating: '9.8', isRed: true),
                    const SizedBox(width: 12),
                    Text('${movie.year}', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Text(movie.quality, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Text(movie.lang, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Play Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (episodes.isNotEmpty) {
                        final resumeEp = progress != null
                            ? episodes.firstWhere((e) => e.slug == progress.episodeSlug, orElse: () => episodes.first)
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nội dung phim',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  movie.content.isNotEmpty ? movie.content : 'Chưa có tóm tắt cho phim này.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                if (movie.actors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Diễn viên', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(movie.actors.join(', '), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
          // Right Column (Episodes Grid & Comments)
          Expanded(
            flex: 52,
            child: ListView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              children: [
                if (movie.episodes.length > 1) ...[
                  const Text('Máy chủ phát', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
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
                          onSelected: (_) => setState(() => _selectedServerIndex = idx),
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
                const SizedBox(height: 32),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 20),
                const Text('Bình luận & Đánh giá', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                MovieCommentsWidget(movieSlug: movie.slug),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
