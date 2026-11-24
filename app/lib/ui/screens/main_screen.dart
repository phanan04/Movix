import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final FocusNode _searchFocusNode = FocusNode();

  // Scroll controllers cho 5 tab điều hướng chuẩn trải nghiệm YouTube, Facebook, Twitter
  // Nhấn vào tab đang chọn -> cuộn mượt mà lên đầu trang
  final ScrollController _homeScrollController = ScrollController();
  final ScrollController _exploreScrollController = ScrollController();
  final ScrollController _myListFavScrollController = ScrollController();
  final ScrollController _myListHistScrollController = ScrollController();
  final ScrollController _downloadScrollController = ScrollController();
  final ScrollController _profileScrollController = ScrollController();

  @override
  void dispose() {
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
    IconData icon,
    String label, {
    bool requestFocus = false,
  }) {
    final isSelected = _currentIndex == index;
    return Tooltip(
      message: label,
      preferBelow: false,
      child: SizedBox(
        width: double.infinity,
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vạch indicator nhỏ màu đỏ #E50914 sát mép trái khi Active
            if (isSelected)
              Positioned(
                left: 0,
                top: 7,
                bottom: 7,
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

            // Nền bo góc vuông BorderRadius.circular(10) với TVFocusable
            TVFocusable(
              onPressed: () => _switchTab(index, requestFocus: requestFocus),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryMuted
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    size: 22,
                  ),
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
        onPressed: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppColors.textMuted,
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
          onPressed: null,
          borderRadius: BorderRadius.circular(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logo.png',
              width: 42,
              height: 42,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletSidebar(BuildContext context) {
    return Container(
      width: 68,
      decoration: const BoxDecoration(
        color: Color(0xFF0B0C0E),
        border: Border(
          right: BorderSide(
            color: Color(0x14FFFFFF),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            // 1. TOP: Nút Logo tích hợp Dropdown chuyển nguồn (TMDb / KKPhim)
            _buildSidebarSourceSwitcher(context),

            const Spacer(),

            // 2. CENTER: Cụm điều hướng chính căn giữa theo chiều dọc
            _buildSidebarItem(1, Icons.search_rounded, 'Tìm kiếm', requestFocus: true),
            const SizedBox(height: 22),
            _buildSidebarItem(0, Icons.home_rounded, 'Trang chủ'),
            const SizedBox(height: 22),
            _buildSidebarItem(2, Icons.bookmark_rounded, 'Danh sách của tôi'),
            const SizedBox(height: 22),
            _buildSidebarItem(3, Icons.file_download_rounded, 'Tải xuống'),

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
            const SizedBox(height: 18),
            _buildSidebarItem(4, Icons.person_rounded, 'Tài khoản'),
            const SizedBox(height: 18),
          ],
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
      ),
      ExploreScreen(
        focusNode: _searchFocusNode,
        scrollController: _exploreScrollController,
      ),
      MyListScreen(
        scrollController: _myListFavScrollController,
        historyScrollController: _myListHistScrollController,
      ),
      DownloadScreen(
        onExploreTap: () => _switchTab(1, requestFocus: false),
        scrollController: _downloadScrollController,
      ),
      ProfileScreen(
        scrollController: _profileScrollController,
      ),
    ];

    if (isTabletLandscape) {
      // Tablet Landscape / Wide Screen Layout: Sleek Side Navigation Rail
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _buildTabletSidebar(context),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
          ],
        ),
      );
    }

    // Standard Mobile Phone Layout
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1014),
          border: Border(
            top: BorderSide(color: Color(0xFF1F222A), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F1014),
          currentIndex: _currentIndex,
          onTap: (index) => _switchTab(index, requestFocus: false),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_filled),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Khám phá',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border_rounded),
              activeIcon: Icon(Icons.bookmark_rounded),
              label: 'Danh sách',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.file_download_outlined),
              activeIcon: Icon(Icons.file_download_rounded),
              label: 'Tải xuống',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
