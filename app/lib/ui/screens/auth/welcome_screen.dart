import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'lets_you_in_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Chào mừng đến với Movix',
      'subtitle': 'Trải nghiệm kho tàng hàng ngàn bộ phim bom tấn và series hấp dẫn nhất thế giới.',
      'image': 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Xem phim không giới hạn',
      'subtitle': 'Tận hưởng chất lượng Full HD, âm thanh vòm sống động và không bị quảng cáo làm phiền.',
      'image': 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=800&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Tải xuống & Xem ngoại tuyến',
      'subtitle': 'Dễ dàng tải về máy những bộ phim yêu thích để thưởng thức bất kỳ lúc nào, mọi nơi.',
      'image': 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&auto=format&fit=crop&q=80',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    slide['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.surface),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x990F1014),
                          AppColors.background,
                        ],
                        stops: [0.2, 0.65, 1.0],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Bottom Content & Actions
          Positioned(
            left: 20,
            right: 20,
            bottom: 36,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _slides[_currentPage]['title']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _slides[_currentPage]['subtitle']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pagination Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isSelected = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LetsYouInScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Bắt đầu ngay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
