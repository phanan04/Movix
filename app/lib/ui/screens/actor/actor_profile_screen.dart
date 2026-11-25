import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/movie_model.dart';
import '../../../core/services/tmdb_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/movie_providers.dart';
import '../../widgets/cached_poster_image.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/tv_focusable.dart';
import '../movie_detail/movie_detail_screen.dart';

class ActorProfileScreen extends ConsumerStatefulWidget {
  final int personId;
  final String name;
  final String? profileUrl;

  const ActorProfileScreen({
    super.key,
    required this.personId,
    required this.name,
    this.profileUrl,
  });

  @override
  ConsumerState<ActorProfileScreen> createState() => _ActorProfileScreenState();
}

class _ActorProfileScreenState extends ConsumerState<ActorProfileScreen> {
  bool _isBioExpanded = false;

  void _openMovie(TmdbPersonCredit credit) {
    final year = credit.releaseDate != null && credit.releaseDate!.length >= 4
        ? (int.tryParse(credit.releaseDate!.substring(0, 4)) ?? 0)
        : 0;
    final preview = MovieItem(
      id: credit.id.toString(),
      name: credit.title,
      originName: credit.originalTitle ?? credit.title,
      slug: 'tmdb-${credit.id}',
      thumbUrl: credit.posterUrl ?? '',
      posterUrl: credit.posterUrl ?? '',
      year: year,
      episodeCurrent: credit.mediaType == 'tv' ? 'Series' : 'Full',
      quality: credit.voteAverage > 0 ? '${credit.voteAverage.toStringAsFixed(1)} ★' : 'FHD',
      lang: 'Quốc Tế',
      voteAverage: credit.voteAverage,
      tmdbId: credit.id,
      tmdbMediaType: credit.mediaType,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(
          slug: preview.slug,
          tmdbId: credit.id,
          tmdbMediaType: credit.mediaType,
          previewMovie: preview,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = widget.personId > 0
        ? ref.watch(personDetailsProvider(widget.personId))
        : ref.watch(personDetailsByNameProvider(widget.name));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Nav
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    TVFocusable(
                      onPressed: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12, width: 0.8),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Hồ sơ Nghệ sĩ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Header profile info
            SliverToBoxAdapter(
              child: detailsAsync.when(
                data: (details) {
                  final profile = details?.profileUrl ?? widget.profileUrl;
                  final bio = details?.biography.trim() ?? '';
                  final birthday = details?.birthday;
                  final birthplace = details?.placeOfBirth;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar lớn với viền sáng
                        Container(
                          width: 124,
                          height: 124,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: profile != null
                                ? CachedPosterImage(
                                    imageUrl: profile,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 250,
                                    memCacheHeight: 250,
                                  )
                                : Container(
                                    color: const Color(0xFF232530),
                                    child: Center(
                                      child: Text(
                                        widget.name.isNotEmpty ? widget.name[0] : '?',
                                        style: const TextStyle(fontSize: 42, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Tên nghệ sĩ
                        Text(
                          widget.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),

                        // Ngày sinh & Quê quán
                        if (birthday != null || birthplace != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            [if (birthday != null) birthday, if (birthplace != null) birthplace].join(' • '),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        // Tiểu sử
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                bio,
                                maxLines: _isBioExpanded ? 30 : 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFCCCCCC),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      ShimmerSkeleton(width: 124, height: 124, borderRadius: 62),
                      SizedBox(height: 14),
                      ShimmerSkeleton(width: 180, height: 22, borderRadius: 8),
                      SizedBox(height: 10),
                      ShimmerSkeleton(width: double.infinity, height: 64, borderRadius: 10),
                    ],
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Section title: Các phim đã tham gia
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    const Icon(Icons.movie_filter_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Tác phẩm tiêu biểu (TMDb Filmography)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filmography grid
            detailsAsync.when(
              data: (details) {
                final credits = details?.credits ?? [];
                if (credits.isEmpty) {
                  return SliverToBoxAdapter(
                    child: FutureBuilder<List<MovieItem>>(
                      future: ref.read(apiServiceProvider).searchMovies(widget.name, limit: 10),
                      builder: (context, snapshot) {
                        final movies = snapshot.data ?? [];
                        if (movies.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('Chưa có danh sách phim.', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 160,
                              childAspectRatio: 0.58,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: movies.length,
                            itemBuilder: (context, idx) {
                              final item = movies[idx];
                              return TVFocusable(
                                onPressed: () {
                                  Navigator.push(
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
                                child: MovieCard(movie: item),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) {
                        final credit = credits[idx];
                        return TVFocusable(
                          onPressed: () => _openMovie(credit),
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
                                      if (credit.posterUrl != null)
                                        CachedPosterImage(
                                          imageUrl: credit.posterUrl!,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 260,
                                          memCacheHeight: 380,
                                        )
                                      else
                                        Container(
                                          color: const Color(0xFF1E212A),
                                          child: const Center(
                                            child: Icon(Icons.movie_outlined, color: Colors.white38, size: 32),
                                          ),
                                        ),
                                      if (credit.voteAverage > 0)
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.75),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 11),
                                                const SizedBox(width: 2),
                                                Text(
                                                  credit.voteAverage.toStringAsFixed(1),
                                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                credit.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (credit.character != null && credit.character!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  credit.character!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                      childCount: credits.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: PosterGridSkeleton(
                  crossAxisCount: 3,
                  itemCount: 6,
                  childAspectRatio: 0.58,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: Center(child: Text('Không thể tải tác phẩm.', style: TextStyle(color: AppColors.textSecondary))),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }
}
