import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';
import 'my_list/my_list_screen.dart';
import 'download/download_screen.dart';
import 'profile/profile_screen.dart';
import 'home/notification_screen.dart';
import '../widgets/tv_focusable.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _switchTab(int index, {bool requestFocus = false}) {
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
                    color: Color(0xFFE50914),
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
                      ? const Color(0xFFE50914).withValues(alpha: 0.14)
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
            // 1. TOP: Logo Movix điện ảnh
            Padding(
              padding: const EdgeInsets.only(top: 16),
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
    final width = MediaQuery.of(context).size.width;
    final isTabletLandscape = width >= 600;

    final pages = [
      HomeScreen(onSearchTap: () => _switchTab(1, requestFocus: true)),
      ExploreScreen(focusNode: _searchFocusNode),
      const MyListScreen(),
      DownloadScreen(onExploreTap: () => _switchTab(1, requestFocus: false)),
      const ProfileScreen(),
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
