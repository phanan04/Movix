import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/movie_providers.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';
import 'my_list/my_list_screen.dart';
import 'download/download_screen.dart';
import 'profile/profile_screen.dart';
import 'home/notification_screen.dart';
import '../widgets/tv_focusable.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<PopupMenuButtonState<AppSourceMode>> _sourceMenuKey = GlobalKey<PopupMenuButtonState<AppSourceMode>>();
  late final AnimationController _tabFadeController;
  late final Animation<double> _tabFadeAnimation;

  // Scroll controllers cho 5 tab điều hướng chuẩn trải nghiệm YouTube, Facebook, Twitter
  // Nhấn vào tab đang chọn -> cuộn mượt mà lên đầu trang
  final ScrollController _homeScrollController = ScrollController();
  final ScrollController _exploreScrollController = ScrollController();
  final ScrollController _myListFavScrollController = ScrollController();
  final ScrollController _myListHistScrollController = ScrollController();
  final ScrollController _downloadScrollController = ScrollController();
  final ScrollController _profileScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
      value: 1.0,
    );
    _tabFadeAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _tabFadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tabFadeController.dispose();
    _searchFocusNode.dispose();
    _homeScrollController.dispose();
    _exploreScrollController.dispose();
    _myListFavScrollController.dispose();
    _myListHistScrollController.dispose();
    _downloadScrollController.dispose();
    _profileScrollController.dispose();
    super.dispose();
  }

  void _scrollToTop(ScrollController controller) {
    if (controller.hasClients) {
      controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _switchTab(int index, {bool requestFocus = false}) {
    HapticFeedback.selectionClick();
    if (_currentIndex == index) {
      // Khi người dùng bấm vào tab hiện tại -> cuộn mượt lên đầu (chuẩn YouTube / Facebook)
      switch (index) {
        case 0:
          _scrollToTop(_homeScrollController);
          break;
        case 1:
          _scrollToTop(_exploreScrollController);
          break;
        case 2:
          _scrollToTop(_myListFavScrollController);
          _scrollToTop(_myListHistScrollController);
          break;
        case 3:
          _scrollToTop(_downloadScrollController);
          break;
        case 4:
          _scrollToTop(_profileScrollController);
          break;
      }
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    _tabFadeController.forward(from: 0.0);
    if (index == 1 && requestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_searchFocusNode.hasFocus) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  Widget _buildSidebarItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label, {
    bool requestFocus = false,
  }) {
    final isSelected = _currentIndex == index;
    return Tooltip(
      message: label,
      preferBelow: false,
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vạch đỏ dọc sát mép trái khi đang chọn
            if (isSelected)
              Positioned(
                left: 0,
                top: 9,
                bottom: 9,
                child: Container(
                  width: 3.5,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
              ),

            TVFocusable(
              showBorder: false,
              onPressed: () => _switchTab(index, requestFocus: requestFocus),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.62),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      preferBelow: false,
      child: TVFocusable(
        showBorder: false,
        onPressed: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.62),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSourceSwitcher(BuildContext context) {
    final currentMode = ref.watch(appSourceModeProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: PopupMenuButton<AppSourceMode>(
        key: _sourceMenuKey,
        tooltip: 'Chuyển nguồn: TMDb / KKPhim',
        offset: const Offset(62, 0),
        constraints: const BoxConstraints(minWidth: 130, maxWidth: 160),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x28FFFFFF), width: 0.8),
        ),
        color: const Color(0xFF16181F),
        elevation: 12,
        initialValue: currentMode,
        onSelected: (mode) {
          HapticFeedback.selectionClick();
          ref.read(appSourceModeProvider.notifier).state = mode;
        },
        itemBuilder: (context) => [
          PopupMenuItem<AppSourceMode>(
            value: AppSourceMode.tmdb,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'TMDb',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: currentMode == AppSourceMode.tmdb ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14.5,
                  ),
                ),
                const Spacer(),
                if (currentMode == AppSourceMode.tmdb)
                  const Icon(Icons.check, color: AppColors.primary, size: 18),
              ],
            ),
          ),
          PopupMenuItem<AppSourceMode>(
            value: AppSourceMode.kkphim,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'KKPhim',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: currentMode == AppSourceMode.kkphim ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14.5,
                  ),
                ),
                const Spacer(),
                if (currentMode == AppSourceMode.kkphim)
                  const Icon(Icons.check, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ],
        child: TVFocusable(
          onPressed: () => _sourceMenuKey.currentState?.showButtonMenu(),
          borderRadius: BorderRadius.circular(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logo.png',
              width: 38,
              height: 38,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletSidebar(BuildContext context) {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.black.withValues(alpha: 0.62),
            Colors.black.withValues(alpha: 0.24),
            Colors.transparent,
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            // 1. TOP: Nút Logo tích hợp Dropdown chuyển nguồn (TMDb / KKPhim)
            _buildSidebarSourceSwitcher(context),

            const Spacer(),

            // 2. CENTER: Cụm điều hướng chính chỉ icon, căn giữa theo chiều dọc
            _buildSidebarItem(0, Icons.home_rounded, Icons.home_outlined, 'Trang chủ'),
            const SizedBox(height: 18),
            _buildSidebarItem(1, Icons.search_rounded, Icons.search_rounded, 'Tìm kiếm', requestFocus: true),
            const SizedBox(height: 18),
            _buildSidebarItem(2, Icons.bookmark_rounded, Icons.bookmark_border_rounded, 'Danh sách của tôi'),
            const SizedBox(height: 18),
            _buildSidebarItem(3, Icons.file_download_rounded, Icons.file_download_outlined, 'Tải xuống'),

            const Spacer(),

            // 3. BOTTOM: Icon Thông báo và Tài khoản
            _buildSidebarActionButton(
              icon: Icons.notifications_none_rounded,
              label: 'Thông báo',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildSidebarItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Tài khoản'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPillBottomBar(BuildContext context) {
    final navItems = [
      (Icons.home_rounded, Icons.home_outlined, 'Trang chủ'),
      (Icons.explore_rounded, Icons.explore_outlined, 'Khám phá'),
      (Icons.bookmark_rounded, Icons.bookmark_border_rounded, 'Danh sách'),
      (Icons.file_download_rounded, Icons.file_download_outlined, 'Tải xuống'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Cá nhân'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 64,
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1116).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = _currentIndex == index;
              return Expanded(
                child: TVFocusable(
                  showBorder: false,
                  scale: 0.94,
                  onPressed: () => _switchTab(index, requestFocus: false),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              width: 0.8,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopIconSwitch(
                          child: Icon(
                            isSelected ? item.$1 : item.$2,
                            key: ValueKey('${item.$3}_$isSelected'),
                            size: 21,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.55),
                            letterSpacing: -0.2,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Chỉ kích hoạt Sidebar cho Máy tính bảng thực thụ (shortestSide >= 600) hoặc PC Desktop Web rộng
    // Điện thoại di động (kể cả xoay ngang thì shortestSide chỉ ~390px) luôn dùng giao diện Mobile chuẩn!
    final isTabletLandscape = media.size.shortestSide >= 600 || (kIsWeb && media.size.width >= 900);

    final pages = [
      HomeScreen(
        onSearchTap: () => _switchTab(1, requestFocus: true),
        scrollController: _homeScrollController,
        hasOverlayRail: isTabletLandscape,
      ),
      Padding(
        padding: EdgeInsets.only(left: isTabletLandscape ? 64 : 0),
        child: ExploreScreen(
          focusNode: _searchFocusNode,
          scrollController: _exploreScrollController,
        ),
      ),
      Padding(
        padding: EdgeInsets.only(left: isTabletLandscape ? 64 : 0),
        child: MyListScreen(
          scrollController: _myListFavScrollController,
          historyScrollController: _myListHistScrollController,
        ),
      ),
      Padding(
        padding: EdgeInsets.only(left: isTabletLandscape ? 64 : 0),
        child: DownloadScreen(
          onExploreTap: () => _switchTab(1, requestFocus: false),
          scrollController: _downloadScrollController,
        ),
      ),
      Padding(
        padding: EdgeInsets.only(left: isTabletLandscape ? 64 : 0),
        child: ProfileScreen(
          scrollController: _profileScrollController,
        ),
      ),
    ];

    if (isTabletLandscape) {
      // Tablet Landscape / Wide Screen Layout: Transparent Icon-Only Rail overlaid on Hero
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: _tabFadeAnimation,
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 64,
              child: _buildTabletSidebar(context),
            ),
          ],
        ),
      );
    }

    // Standard Mobile Phone Layout: Modern Floating iOS Pill Bar
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _tabFadeAnimation,
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: bottomInset > 0 ? bottomInset + 4 : 16,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildModernPillBottomBar(context),
            ),
          ),
        ],
      ),
    );
  }
}
