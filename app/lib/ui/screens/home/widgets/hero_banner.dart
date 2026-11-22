import 'package:flutter/material.dart';
import '../../../../core/models/movie_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/cache/user_storage.dart';
import '../../../widgets/cached_poster_image.dart';
import '../../../widgets/tv_focusable.dart';
import '../../movie_detail/movie_detail_screen.dart';

class HeroBanner extends StatefulWidget {
  final MovieItem? movie;

  const HeroBanner({super.key, this.movie});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final UserStorage _userStorage = UserStorage();

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final isShortLandscape = isWide && screenHeight < 500;

    // Chiều cao Hero Banner: Tự co giãn thông minh theo màn hình
    // Trên điện thoại xoay ngang (iPhone 16 landscape ~852x393), ưu tiên chiều cao 320-360px để không cấn chữ
    final bannerHeight = isShortLandscape
        ? (screenHeight * 0.88).clamp(320.0, 380.0)
        : (isWide ? (screenHeight * 0.56).clamp(420.0, 600.0) : screenHeight * 0.48);

    final double btnHeight = isShortLandscape ? 36.0 : (isWide ? 42.0 : 40.0);
    const double btnRadius = 8.0;

    if (movie == null) {
      return Container(
        height: bannerHeight,
        color: AppColors.surface,
      );
    }

    return RepaintBoundary(
      child: SizedBox(
        height: bannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image: Dùng ảnh ngang 16:9 (backdropUrl) cho màn hình rộng/TV/Landscape, poster dọc (verticalPosterUrl) cho mobile dọc
            CachedPosterImage(
              imageUrl: isWide ? movie.backdropUrl : movie.verticalPosterUrl,
              fit: BoxFit.cover,
              alignment: isWide ? Alignment.center : Alignment.topCenter,
              memCacheWidth: 1280,
              memCacheHeight: 720,
            ),

            // 2. Lớp gradient ngang (LinearGradient từ trái sang) trên màn hình rộng chuẩn Netflix
            if (isWide)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0F1014).withValues(alpha: 0.96),
                      const Color(0xFF0F1014).withValues(alpha: 0.75),
                      const Color(0xFF0F1014).withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.60, 0.90],
                  ),
                ),
              ),

            // 3. Top gradient for status bar and top icons
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Color(0x990F1014),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // 4. Bottom gradient overlay (fade into #0F1014)
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
            ),

            // 5. Bottom Content (Title, Metadata, Netflix Action Buttons)
            Positioned(
              left: isWide ? (isShortLandscape ? 24 : 48) : 16,
              right: isWide ? screenWidth * 0.40 : 16,
              bottom: isShortLandscape ? 12 : 24,
              child: Column(
                crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    movie.name,
                    textAlign: isWide ? TextAlign.left : TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isShortLandscape ? 22 : (isWide ? 32 : 24),
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.15,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1.5)),
                        Shadow(color: Colors.black87, blurRadius: 16),
                      ],
                    ),
                  ),
                  SizedBox(height: isShortLandscape ? 4 : 8),

                  // Metadata: Year • Quality • Categories
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
                    children: [
                      if (movie.year > 0)
                        Text(
                          '${movie.year}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (movie.quality.isNotEmpty) ...[
                        const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.borderLight, width: 0.8),
                          ),
                          child: Text(
                            movie.quality.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (movie.categoryNames.isNotEmpty) ...[
                        const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        Text(
                          movie.categoryNames.take(3).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isShortLandscape ? 10 : 16),

                  // Cụm nút hành động chuẩn Netflix: Đều chiều cao trên cùng 1 hàng
                  Row(
                    mainAxisSize: isWide ? MainAxisSize.min : MainAxisSize.max,
                    mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      // Nút "Xem ngay" (Play) chuẩn Movix: Nền Đỏ #E50914 chữ Trắng đồng nhất toàn app
                      TVFocusable(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(slug: movie.slug),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(btnRadius),
                        child: Container(
                          height: btnHeight,
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? (isShortLandscape ? 16 : 22) : 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(btnRadius),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: AppColors.textPrimary, size: isShortLandscape ? 18 : 22),
                              const SizedBox(width: 5),
                              Text(
                                'Xem ngay',
                                style: TextStyle(
                                  fontSize: isShortLandscape ? 12.5 : 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: isShortLandscape ? 8 : 12),

                      // Nút "Chi tiết" (Info): Màn dọc chỉ hiện icon trong khung vuông, Màn ngang hiện chữ + icon
                      TVFocusable(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(slug: movie.slug),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(btnRadius),
                        child: Container(
                          height: btnHeight,
                          width: isWide ? null : btnHeight,
                          padding: isWide
                              ? EdgeInsets.symmetric(horizontal: isShortLandscape ? 12 : 18)
                              : EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(btnRadius),
                            border: Border.all(color: AppColors.borderLight, width: 1),
                          ),
                          child: Center(
                            child: isWide
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.info_outline_rounded, color: AppColors.textPrimary, size: isShortLandscape ? 16 : 18),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Chi tiết',
                                        style: TextStyle(
                                          fontSize: isShortLandscape ? 12.5 : 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Icon(Icons.info_outline_rounded, color: AppColors.textPrimary, size: 20),
                          ),
                        ),
                      ),
                      SizedBox(width: isShortLandscape ? 8 : 12),

                      // Nút "Lưu lại" (My List): Màn dọc chỉ hiện icon trong khung vuông, Màn ngang hiện chữ + icon
                      ValueListenableBuilder<List<MovieItem>>(
                        valueListenable: _userStorage.myListNotifier,
                        builder: (context, _, __) {
                          final inList = _userStorage.isInMyList(movie.slug);
                          return TVFocusable(
                            onPressed: () {
                              _userStorage.toggleMyList(movie);
                            },
                            borderRadius: BorderRadius.circular(btnRadius),
                            child: Container(
                              height: btnHeight,
                              width: isWide ? null : btnHeight,
                              padding: isWide
                                  ? EdgeInsets.symmetric(horizontal: isShortLandscape ? 14 : 18)
                                  : EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: inList
                                    ? AppColors.primaryMuted
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(btnRadius),
                                border: Border.all(
                                  color: inList ? AppColors.primary : AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: isWide
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            inList ? Icons.check_rounded : Icons.add_rounded,
                                            color: inList ? AppColors.primary : AppColors.textPrimary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            inList ? 'Đã lưu' : 'Lưu lại',
                                            style: TextStyle(
                                              fontSize: isShortLandscape ? 12.5 : 14,
                                              fontWeight: FontWeight.w600,
                                              color: inList ? AppColors.primary : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Icon(
                                        inList ? Icons.check_rounded : Icons.add_rounded,
                                        color: inList ? AppColors.primary : AppColors.textPrimary,
                                        size: 20,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
