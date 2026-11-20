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

  Widget _buildSidebarItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return Tooltip(
      message: label,
      preferBelow: false,
      child: InkWell(
        onTap: () => _switchTab(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : AppColors.textMuted,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletSidebar(BuildContext context) {
    return Container(
      width: 64,
      color: const Color(0xFF14161D),
      child: SafeArea(
        right: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // 1. Red 'M' Icon (Icon Only, No text)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
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
              const SizedBox(height: 10),

              // 2. Header Action Buttons moved into Sidebar
              Tooltip(
                message: 'Tìm kiếm',
                preferBelow: false,
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white70, size: 22),
                  onPressed: () => _switchTab(1),
                ),
              ),
              Tooltip(
                message: 'Thông báo',
                preferBelow: false,
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 22),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              const Divider(color: AppColors.border, height: 1, indent: 12, endIndent: 12),
              const SizedBox(height: 4),

              // 3. Navigation Destinations (Icon-only: Always stays inside frame on all tablet screens)
              _buildSidebarItem(0, Icons.home_outlined, Icons.home_filled, 'Trang chủ'),
              _buildSidebarItem(1, Icons.explore_outlined, Icons.explore_rounded, 'Khám phá'),
              _buildSidebarItem(2, Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'Danh sách'),
              _buildSidebarItem(3, Icons.file_download_outlined, Icons.file_download_rounded, 'Tải xuống'),
              _buildSidebarItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Cá nhân'),
              const SizedBox(height: 12),
            ],
          ),
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
