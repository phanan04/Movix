import 'package:flutter/material.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/models/movie_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/cached_poster_image.dart';
import '../movie_detail/movie_detail_screen.dart';

class MyListScreen extends StatefulWidget {
  final ScrollController? scrollController;
  final ScrollController? historyScrollController;

  const MyListScreen({
    super.key,
    this.scrollController,
    this.historyScrollController,
  });

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserStorage _userStorage = UserStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Danh sách của tôi'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Yêu thích'),
            Tab(text: 'Lịch sử xem'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFavoritesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        await _userStorage.init();
      },
      child: ValueListenableBuilder<List<MovieItem>>(
        valueListenable: _userStorage.myListNotifier,
        builder: (context, movies, _) {
          if (movies.isEmpty) {
            return ListView(
              controller: widget.scrollController,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border_rounded, size: 72, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'Danh sách yêu thích đang trống',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Hãy nhấn biểu tượng Bookmark ở phim bạn muốn xem sau',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1000
                  ? 5
                  : (constraints.maxWidth >= 720
                      ? 4
                      : (constraints.maxWidth >= 480 ? 3 : 2));

              return GridView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 16,
                ),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  return GridMovieCard(movie: movies[index]);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        await _userStorage.init();
      },
      child: ValueListenableBuilder<List<WatchProgress>>(
        valueListenable: _userStorage.historyNotifier,
        builder: (context, historyList, _) {
          if (historyList.isEmpty) {
            return ListView(
              controller: widget.historyScrollController,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 72, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có lịch sử xem phim',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tiến độ xem sẽ tự động lưu lại khi bạn xem phim',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            controller: widget.historyScrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: historyList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = historyList[index];
              final mins = (item.positionSeconds / 60).floor();

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(slug: item.movieSlug),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CachedPosterImage(
                            imageUrl: item.posterUrl,
                            width: 75,
                            height: 100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                              child: LinearProgressIndicator(
                                value: item.progressPercentage,
                                backgroundColor: Colors.black45,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                minHeight: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.movieName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đang xem: ${item.episodeName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đã xem $mins phút / ${(item.durationSeconds / 60).floor()} phút',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 32),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
