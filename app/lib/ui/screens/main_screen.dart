import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';
import 'my_list/my_list_screen.dart';
import 'download/download_screen.dart';
import 'profile/profile_screen.dart';
import 'home/notification_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Tooltip(
      message: label,
      preferBelow: false,
      child: InkWell(
        onTap: () => _switchTab(index),
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

              // Nền bo góc vuông BorderRadius.circular(10) màu xám/đỏ mờ + icon trắng sáng khi Active
              Container(
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
            ],
          ),
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
      child: InkWell(
        onTap: onTap,
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
      width: 66,
      color: const Color(0xFF14161D),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            // 1. TOP: Logo chữ 'M' màu đỏ, căn thẳng hàng ngang với thanh Search
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // 2. CENTER: Cụm điều hướng chính căn giữa theo chiều dọc
            // (Home, Explore, Bookmark, Download) với khoảng cách dọc đều nhau 24px
            _buildSidebarItem(0, Icons.home_outlined, 'Trang chủ'),
            const SizedBox(height: 24),
            _buildSidebarItem(1, Icons.explore_outlined, 'Khám phá'),
            const SizedBox(height: 24),
            _buildSidebarItem(2, Icons.bookmark_border_rounded, 'Đã lưu'),
            const SizedBox(height: 24),
            _buildSidebarItem(3, Icons.file_download_outlined, 'Tải xuống'),

            const Spacer(),

            // 3. BOTTOM: Icon Thông báo và Tài khoản sát đáy Sidebar với khoảng cách 20px
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
            const SizedBox(height: 20),
            _buildSidebarItem(4, Icons.person_outline_rounded, 'Tài khoản'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTabletLandscape = width >= 720;

    final pages = [
      HomeScreen(onSearchTap: () => _switchTab(1)),
      const ExploreScreen(),
      const MyListScreen(),
      DownloadScreen(onExploreTap: () => _switchTab(1)),
      const ProfileScreen(),
    ];

    if (isTabletLandscape) {
      // Tablet Landscape / Wide Screen Layout: Sleek Side Navigation Rail
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _buildTabletSidebar(context),
            const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
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
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _switchTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              label: 'Khám phá',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_rounded),
              label: 'Danh sách',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.file_download_outlined),
              label: 'Tải xuống',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
