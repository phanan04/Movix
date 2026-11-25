import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CachedPosterImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CachedPosterImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  String _getProcessedUrl(String url) {
    if (url.isEmpty) return '';
    // On Web, proxy all external images through server proxy to bypass browser canvas CORS limitations
    if (kIsWeb) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
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
        alignment: alignment,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: AppColors.surface,
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
