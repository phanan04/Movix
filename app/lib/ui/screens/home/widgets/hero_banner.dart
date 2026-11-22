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
            // 1. Background Image: Dùng ảnh ngang 16:9 (posterUrl) cho màn hình rộng/TV/Landscape, poster dọc (thumbUrl) cho mobile dọc
            CachedPosterImage(
              imageUrl: isWide
                  ? movie.fullPosterUrl
                  : (movie.fullThumbUrl.isNotEmpty ? movie.fullThumbUrl : movie.fullPosterUrl),
              fit: BoxFit.cover,
              alignment: isWide ? Alignment.centerRight : Alignment.topCenter,
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
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (movie.quality.isNotEmpty) ...[
                        const Text('•', style: TextStyle(color: Color(0xFF808080), fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: Colors.white30, width: 0.8),
                          ),
                          child: Text(
                            movie.quality.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (movie.categoryNames.isNotEmpty) ...[
                        const Text('•', style: TextStyle(color: Color(0xFF808080), fontSize: 13)),
                        Text(
                          movie.categoryNames.take(3).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFB3B3B3),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isShortLandscape ? 10 : 16),

                  // Cụm nút hành động chuẩn Netflix: [▶ Xem ngay (Nền trắng)] + [ℹ Chi tiết] + [Lưu lại]
                  Wrap(
                    spacing: isShortLandscape ? 8 : 12,
                    runSpacing: 8,
                    alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
                    children: [
                      // Nút "Xem ngay" (Play) chuẩn Netflix TV: Nền trắng chữ đen
                      TVFocusable(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(slug: movie.slug),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isShortLandscape ? 14 : 22,
                            vertical: isShortLandscape ? 6 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: Colors.black, size: isShortLandscape ? 18 : 22),
                              const SizedBox(width: 4),
                              Text(
                                'Xem ngay',
                                style: TextStyle(
                                  fontSize: isShortLandscape ? 12.5 : 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Nút "Chi tiết" (Info)
                      TVFocusable(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(slug: movie.slug),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isShortLandscape ? 12 : 18,
                            vertical: isShortLandscape ? 6 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2028).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.white, size: isShortLandscape ? 16 : 18),
                              const SizedBox(width: 4),
                              Text(
                                'Chi tiết',
                                style: TextStyle(
                                  fontSize: isShortLandscape ? 12.5 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Nút "+ Danh sách" (My List)
                      ValueListenableBuilder<List<MovieItem>>(
                        valueListenable: _userStorage.myListNotifier,
                        builder: (context, _, __) {
                          final inList = _userStorage.isInMyList(movie.slug);
                          return TVFocusable(
                            onPressed: () {
                              _userStorage.toggleMyList(movie);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2028).withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: inList ? const Color(0xFFE50914) : Colors.white24,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    inList ? Icons.check_rounded : Icons.add_rounded,
                                    color: inList ? const Color(0xFFE50914) : Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    inList ? 'Đã lưu' : 'Lưu lại',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: inList ? const Color(0xFFE50914) : Colors.white,
                                    ),
                                  ),
                                ],
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
