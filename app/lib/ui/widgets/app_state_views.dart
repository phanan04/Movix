import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'shimmer_loading.dart';

/// Trạng thái Lỗi thân thiện (Error State)
class AppErrorStateWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorStateWidget({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.wifi_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 1),
              ),
              child: Icon(icon, color: Colors.redAccent, size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message != null && message!.isNotEmpty
                  ? (message!.contains('SocketException') || message!.contains('Failed host lookup')
                      ? 'Vui lòng kiểm tra lại kết nối mạng Internet của bạn.'
                      : message!)
                  : 'Đã có lỗi xảy ra khi kết nối tới máy chủ. Vui lòng thử lại sau giây lát.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Thử lại ngay',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Trạng thái Danh sách trống thân thiện (Empty State)
class AppEmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12, width: 0.8),
              ),
              child: Icon(icon, color: Colors.white38, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton Shimmer Loading cho Màn hình Chi tiết Phim
class MovieDetailSkeleton extends StatelessWidget {
  const MovieDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  ShimmerSkeleton(width: 36, height: 36, borderRadius: 18),
                  const Spacer(),
                  ShimmerSkeleton(width: 36, height: 36, borderRadius: 18),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Hero / Details skeleton
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vertical Poster placeholder
                    ShimmerSkeleton(width: 140, height: 210, borderRadius: 12),
                    const SizedBox(width: 20),
                    // Metadata lines placeholder
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerSkeleton(width: 220, height: 26, borderRadius: 6),
                          const SizedBox(height: 10),
                          ShimmerSkeleton(width: 140, height: 16, borderRadius: 4),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              ShimmerSkeleton(width: 50, height: 22, borderRadius: 4),
                              const SizedBox(width: 8),
                              ShimmerSkeleton(width: 44, height: 22, borderRadius: 4),
                              const SizedBox(width: 8),
                              ShimmerSkeleton(width: 48, height: 22, borderRadius: 4),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ShimmerSkeleton(width: double.infinity, height: 14, borderRadius: 4),
                          const SizedBox(height: 6),
                          ShimmerSkeleton(width: double.infinity, height: 14, borderRadius: 4),
                          const SizedBox(height: 6),
                          ShimmerSkeleton(width: 180, height: 14, borderRadius: 4),
                          const SizedBox(height: 24),
                          ShimmerSkeleton(width: 160, height: 44, borderRadius: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
