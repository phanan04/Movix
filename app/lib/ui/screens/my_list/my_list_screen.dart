import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/models/movie_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/cached_poster_image.dart';
import '../../widgets/movie_card.dart';
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

  bool _isSelectionMode = false;
  final Set<String> _selectedKeys = {};
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _lastTabIndex) {
        _lastTabIndex = _tabController.index;
        if (_isSelectionMode) {
          _exitSelectionMode();
        } else if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _favKey(MovieItem m) => m.tmdbId != null ? 'tmdb_${m.tmdbId}' : m.slug;

  void _enterSelectionMode(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      _isSelectionMode = true;
      _selectedKeys
        ..clear()
        ..add(key);
    });
  }

  void _toggleSelection(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedKeys.clear();
    });
  }

  void _toggleSelectAll(List<String> allKeys) {
    setState(() {
      if (_selectedKeys.length >= allKeys.length && allKeys.isNotEmpty) {
        _selectedKeys.clear();
      } else {
        _selectedKeys
          ..clear()
          ..addAll(allKeys);
      }
    });
  }

  Future<void> _confirmAndDeleteSelected({
    required bool isHistoryTab,
    required List<MovieItem> favs,
    required List<WatchProgress> history,
  }) async {
    if (_selectedKeys.isEmpty) return;

    final count = _selectedKeys.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        title: Text(
          isHistoryTab ? 'Xóa $count phim khỏi lịch sử?' : 'Xóa $count phim khỏi yêu thích?',
          style: AppTypography.titleMedium,
        ),
        content: Text(
          isHistoryTab
              ? 'Tiến độ xem của các phim đã chọn sẽ bị xóa khỏi thiết bị và tài khoản.'
              : 'Các phim đã chọn sẽ được gỡ khỏi danh sách Yêu thích.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Hủy',
              style: AppTypography.buttonMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Xóa ($count)', style: AppTypography.buttonMedium),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (isHistoryTab) {
        final slugs = history
            .where((h) => _selectedKeys.contains(h.movieSlug))
            .map((h) => h.movieSlug)
            .toList();
        await _userStorage.removeHistoryItems(slugs);
        if (mounted) {
          AppToast.show(context, 'Đã xóa ${slugs.length} phim khỏi lịch sử xem', icon: Icons.delete_outline_rounded);
        }
      } else {
        final items = favs.where((m) => _selectedKeys.contains(_favKey(m))).toList();
        await _userStorage.removeMyListItems(items);
        if (mounted) {
          AppToast.show(context, 'Đã xóa ${items.length} phim khỏi Yêu thích', icon: Icons.bookmark_remove_rounded);
        }
      }
      if (mounted) {
        _exitSelectionMode();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHistoryTab = _tabController.index == 1;

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: _isSelectionMode
              ? IconButton(
                  tooltip: 'Hủy chọn',
                  icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                  onPressed: _exitSelectionMode,
                )
              : null,
          title: Text(
            _isSelectionMode ? 'Đã chọn ${_selectedKeys.length}' : 'Danh sách của tôi',
            style: AppTypography.titleLarge,
          ),
          actions: [
            if (_isSelectionMode)
              ValueListenableBuilder<List<MovieItem>>(
                valueListenable: _userStorage.myListNotifier,
                builder: (context, favs, _) {
                  return ValueListenableBuilder<List<WatchProgress>>(
                    valueListenable: _userStorage.historyNotifier,
                    builder: (context, history, _) {
                      final allKeys = isHistoryTab
                          ? history.map((h) => h.movieSlug).toList()
                          : favs.map(_favKey).toList();
                      final isAllSelected = allKeys.isNotEmpty && _selectedKeys.length >= allKeys.length;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: allKeys.isEmpty ? null : () => _toggleSelectAll(allKeys),
                            child: Text(
                              isAllSelected ? 'Bỏ chọn' : 'Chọn tất cả',
                              style: AppTypography.buttonMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ElevatedButton.icon(
                              onPressed: _selectedKeys.isEmpty
                                  ? null
                                  : () => _confirmAndDeleteSelected(
                                        isHistoryTab: isHistoryTab,
                                        favs: favs,
                                        history: history,
                                      ),
                              icon: const Icon(Icons.delete_outline_rounded, size: 17),
                              label: Text(
                                'Xóa (${_selectedKeys.length})',
                                style: AppTypography.buttonMedium.copyWith(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textPrimary,
                                disabledBackgroundColor: AppColors.surfaceLight,
                                disabledForegroundColor: AppColors.textMuted,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 34),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: ValueListenableBuilder<List<MovieItem>>(
              valueListenable: _userStorage.myListNotifier,
              builder: (context, favs, _) {
                return ValueListenableBuilder<List<WatchProgress>>(
                  valueListenable: _userStorage.historyNotifier,
                  builder: (context, history, _) {
                    return TabBar(
                      controller: _tabController,
                      onTap: (_) => HapticFeedback.selectionClick(),
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorWeight: 3,
                      dividerColor: AppColors.border,
                      labelStyle: AppTypography.titleSmall,
                      unselectedLabelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w500),
                      tabs: [
                        Tab(text: favs.isNotEmpty ? 'Yêu thích (${favs.length})' : 'Yêu thích'),
                        Tab(text: history.isNotEmpty ? 'Lịch sử xem (${history.length})' : 'Lịch sử xem'),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFavoritesTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required ScrollController? controller,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.58,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 72, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(title, style: AppTypography.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionBadge(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.background.withValues(alpha: 0.72),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.7),
          width: 1.6,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, size: 15, color: AppColors.textPrimary)
          : null,
    );
  }

  Widget _buildFavoritesTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => _userStorage.refreshFromCloud(),
      child: ValueListenableBuilder<List<MovieItem>>(
        valueListenable: _userStorage.myListNotifier,
        builder: (context, movies, _) {
          if (movies.isEmpty) {
            return _buildEmptyState(
              controller: widget.scrollController,
              icon: Icons.bookmark_border_rounded,
              title: 'Danh sách yêu thích đang trống',
              subtitle: 'Hãy nhấn biểu tượng Lưu lại ở phim bạn muốn xem sau',
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
                  final movie = movies[index];
                  final key = _favKey(movie);
                  final isSelected = _isSelectionMode && _selectedKeys.contains(key);

                  return GestureDetector(
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        _enterSelectionMode(key);
                      }
                    },
                    onTap: _isSelectionMode ? () => _toggleSelection(key) : null,
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: isSelected
                                ? Border.all(color: AppColors.primary, width: 2.2)
                                : null,
                          ),
                          child: AbsorbPointer(
                            absorbing: _isSelectionMode,
                            child: GridMovieCard(movie: movie),
                          ),
                        ),
                        if (_isSelectionMode)
                          Positioned(
                            right: 10,
                            bottom: 52,
                            child: _buildSelectionBadge(isSelected),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatHistoryProgress(WatchProgress item) {
    if (item.durationSeconds <= 0) {
      return item.positionSeconds > 10
          ? 'Đã xem ${(item.positionSeconds / 60).floor()} phút'
          : 'Vừa mở xem';
    }
    final totalMins = (item.durationSeconds / 60).floor();
    final watchedMins = (item.positionSeconds / 60).floor();
    final remainingSecs = (item.durationSeconds - item.positionSeconds).clamp(0, item.durationSeconds);
    final remainingMins = (remainingSecs / 60).ceil();

    if (item.progressPercentage >= 0.95 || remainingMins <= 0) {
      return 'Đã xem xong ($totalMins phút)';
    }
    return 'Đã xem $watchedMins/$totalMins phút • Còn $remainingMins phút';
  }

  Widget _buildHistoryCard(WatchProgress item) {
    final epLabel = item.episodeName.trim().isNotEmpty ? item.episodeName.trim() : 'Full';
    final isSelected = _isSelectionMode && _selectedKeys.contains(item.movieSlug);

    return InkWell(
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(item.movieSlug);
        }
      },
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(item.movieSlug);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(slug: item.movieSlug),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMuted : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.8 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CachedPosterImage(
                  imageUrl: item.posterUrl,
                  width: 72,
                  height: 98,
                  fit: BoxFit.cover,
                  memCacheWidth: 150,
                  memCacheHeight: 200,
                  borderRadius: BorderRadius.circular(8),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: item.progressPercentage.clamp(0.03, 1.0)),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) {
                        return LinearProgressIndicator(
                          value: val,
                          backgroundColor: Colors.black45,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 4,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.movieName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Đang xem: $epLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatHistoryProgress(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isSelectionMode)
              _buildSelectionBadge(isSelected)
            else
              const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => _userStorage.refreshFromCloud(),
      child: ValueListenableBuilder<List<WatchProgress>>(
        valueListenable: _userStorage.historyNotifier,
        builder: (context, historyList, _) {
          if (historyList.isEmpty) {
            return _buildEmptyState(
              controller: widget.historyScrollController,
              icon: Icons.history_rounded,
              title: 'Chưa có lịch sử xem phim',
              subtitle: 'Tiến độ xem sẽ tự động lưu lại khi bạn xem phim',
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 720) {
                return GridView.builder(
                  controller: widget.historyScrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 120,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: historyList.length,
                  itemBuilder: (context, index) => _buildHistoryCard(historyList[index]),
                );
              }

              return ListView.separated(
                controller: widget.historyScrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: historyList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildHistoryCard(historyList[index]),
              );
            },
          );
        },
      ),
    );
  }
}
