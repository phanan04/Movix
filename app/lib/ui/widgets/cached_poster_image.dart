import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class CachedPosterImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int memCacheWidth;
  final int memCacheHeight;

  const CachedPosterImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.memCacheWidth = 320,
    this.memCacheHeight = 480,
  });

  String _getProcessedUrl(String url) {
    if (url.isEmpty) return '';
    // On Web, proxy through local server proxy to bypass browser canvas CORS limitations
    if (kIsWeb) {
      if (url.startsWith('https://phimimg.com') || url.startsWith('http://phimimg.com')) {
        return '/proxy-image?url=${Uri.encodeComponent(url)}';
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final processedUrl = _getProcessedUrl(imageUrl);

    if (processedUrl.isEmpty) {
      imageWidget = _buildFallback();
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: processedUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceLight,
          child: Container(
            width: width,
            height: height,
            color: AppColors.surface,
          ),
        ),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: AppColors.textMuted,
          size: 32,
        ),
      ),
    );
  }
}
