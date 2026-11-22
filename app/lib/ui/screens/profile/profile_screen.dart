import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../auth/google_auth_service.dart';
import '../auth/lets_you_in_screen.dart';
import '../settings/edit_profile_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../settings/security_screen.dart';
import '../settings/help_center_screen.dart';
import '../settings/privacy_policy_screen.dart';
import '../../widgets/app_toast.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tài khoản & Cài đặt'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await UserStorage().init();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
          // Profile Card (Reactive to login state)
          ValueListenableBuilder<UserModel?>(
            valueListenable: UserStorage().currentUserNotifier,
            builder: (context, user, _) {
              if (user == null) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.surfaceLight,
                        child: Icon(Icons.person_outline, size: 40, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa đăng nhập tài khoản',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Đăng nhập để đồng bộ phim đã lưu, lịch sử xem và bình luận',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LetsYouInScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              child: const Text(
                                'Đăng nhập / Đăng ký',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => GoogleAuthService.showGoogleSignInSheet(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              icon: const Icon(Icons.g_mobiledata_rounded, color: Color(0xFF4285F4), size: 24),
                              label: const Text('Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.surfaceLight,
                          backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                          child: user.avatarUrl.isEmpty
                              ? const Icon(Icons.person, size: 52, color: AppColors.textSecondary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: Text(
                        'VIP Trọn Đời (${user.authProvider.toUpperCase()})',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // Settings Items
          _buildSettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Chỉnh sửa hồ sơ',
            subtitle: 'Đổi tên hiển thị và ảnh đại diện',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            },
          ),
          _buildSettingsTile(
            icon: Icons.security_rounded,
            title: 'Bảo mật & Dữ liệu',
            subtitle: 'Đổi mật khẩu và quản lý dữ liệu xem phim',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityScreen()));
            },
          ),
          _buildSettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Cài đặt thông báo',
            subtitle: 'Tùy chỉnh thông báo phim mới và cập nhật',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
            },
          ),
          _buildSettingsTile(
            icon: Icons.cleaning_services_rounded,
            title: 'Dọn dẹp bộ nhớ đệm (Cache)',
            subtitle: 'Giải phóng RAM và bộ nhớ máy',
            onTap: () {
              CacheManager().clear();
              AppToast.show(context, 'Đã dọn dẹp sạch bộ nhớ đệm cache', icon: Icons.cleaning_services_rounded);
            },
          ),
          _buildSettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Trung tâm trợ giúp (FAQ)',
            subtitle: 'Câu hỏi thường gặp và hướng dẫn sử dụng',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen()));
            },
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Chính sách quyền riêng tư',
            subtitle: 'Bảo mật thông tin và quyền người dùng',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
            },
          ),
          _buildSettingsTile(
            icon: Icons.system_update_rounded,
            title: 'Cập nhật ứng dụng',
            trailingText: 'v1.0.6',
            subtitle: 'Kiểm tra bản phát hành mới nhất',
            onTap: () {
              _showAppUpdateDialog(context);
            },
          ),
          ValueListenableBuilder<UserModel?>(
            valueListenable: UserStorage().currentUserNotifier,
            builder: (context, user, _) {
              if (user != null) {
                return _buildSettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Đăng xuất',
                  isDestructive: true,
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                );
              } else {
                return _buildSettingsTile(
                  icon: Icons.login_rounded,
                  title: 'Đăng nhập vào tài khoản',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LetsYouInScreen()),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.primary : Colors.white70,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.primary : AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (dialogCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đăng xuất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Hủy', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx); // Close modal sheet first
                      try {
                        await FirebaseAuth.instance.signOut();
                      } catch (_) {}
                      await UserStorage().signOut();
                      if (parentContext.mounted) {
                        Navigator.of(parentContext, rootNavigator: true).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LetsYouInScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Đồng ý', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');
      final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final maxLen = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;
      for (int i = 0; i < maxLen; i++) {
        final l = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
      return false;
    } catch (_) {
      return latest != current;
    }
  }

  Future<void> _showAppUpdateDialog(BuildContext context) async {
    const currentVersion = '1.0.6';

    // 1. Hiển thị dialog đang kiểm tra
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingCtx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
              ),
              SizedBox(width: 16),
              Text(
                'Đang kiểm tra bản cập nhật...',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );

    // 2. Fetch GitHub API
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ),
      );

      final response = await dio.get('https://api.github.com/repos/phanan04/Movix/releases/latest');

      // Tắt loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final tagName = (data['tag_name'] ?? '').toString();
        final htmlUrl = (data['html_url'] ?? 'https://github.com/phanan04/Movix/releases').toString();
        final bodyText = (data['body'] ?? '').toString();

        // Tìm asset file APK nếu có
        String? apkDownloadUrl;
        int? apkSize;
        if (data['assets'] is List) {
          final assets = data['assets'] as List;
          for (final asset in assets) {
            if (asset is Map && asset['name'] != null && asset['name'].toString().endsWith('.apk')) {
              apkDownloadUrl = asset['browser_download_url']?.toString();
              apkSize = asset['size'] as int?;
              break;
            }
          }
        }

        final hasNewUpdate = _isNewerVersion(tagName, currentVersion);

        if (!context.mounted) return;

        showDialog(
          context: context,
          builder: (dialogCtx) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(
                    hasNewUpdate ? Icons.system_update_rounded : Icons.check_circle_rounded,
                    color: hasNewUpdate ? AppColors.primary : Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    hasNewUpdate ? 'Có bản cập nhật mới!' : 'Cập nhật ứng dụng',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasNewUpdate
                        ? 'Đã có phiên bản $tagName sẵn sàng để cập nhật.'
                        : 'Bạn đang sử dụng phiên bản Movix mới nhất (v$currentVersion).',
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• Phiên bản hiện tại: v$currentVersion',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 4),
                        if (hasNewUpdate) ...[
                          Text('• Phiên bản mới nhất: $tagName',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (apkSize != null)
                            Text('• Dung lượng APK: ${(apkSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text('• Trạng thái: Cần cập nhật (Update available)',
                              style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ] else ...[
                          const Text('• Nền tảng: Flutter 3.50 & Firebase',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text('• Trạng thái: Bản mới nhất (Latest)',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                  if (hasNewUpdate && bodyText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Thông tin bản phát hành:',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bodyText.split('\n').take(3).join('\n'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(hasNewUpdate ? 'Để sau' : 'Đóng',
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    if (hasNewUpdate && apkDownloadUrl != null) {
                      _downloadAndInstallApk(context, apkDownloadUrl, tagName);
                    } else {
                      final uri = Uri.parse(htmlUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    hasNewUpdate
                        ? (apkDownloadUrl != null ? 'Cập nhật ngay' : 'Xem bản phát hành')
                        : 'Xem trên GitHub',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppToast.show(context, 'Không thể kiểm tra cập nhật. Vui lòng kiểm tra kết nối mạng.');
      }
    }
  }

  // Cập nhật ứng dụng trực tiếp trên thiết bị (In-App APK Download & Install)
  Future<void> _downloadAndInstallApk(
    BuildContext context,
    String downloadUrl,
    String tagName,
  ) async {
    if (kIsWeb) {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    final progressNotifier = ValueNotifier<double>(0.0);
    final statusNotifier = ValueNotifier<String>('Đang chuẩn bị tải...');
    final cancelToken = CancelToken();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.downloading_rounded, color: AppColors.primary, size: 28),
              SizedBox(width: 10),
              Text(
                'Đang cập nhật Movix...',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đang tải gói cài đặt $tagName trực tiếp về máy...',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, progress, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: AppColors.surfaceLight,
                      color: AppColors.primary,
                      minHeight: 8,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<String>(
                valueListenable: statusNotifier,
                builder: (context, status, _) {
                  return Text(
                    status,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelToken.cancel();
                Navigator.of(dlCtx).pop();
              },
              child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        );
      },
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final cleanTag = tagName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final savePath = '${tempDir.path}/Movix_$cleanTag.apk';

      final dio = Dio();
      await dio.download(
        downloadUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            progressNotifier.value = progress;
            final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
            final mbTotal = (total / (1024 * 1024)).toStringAsFixed(1);
            final percent = (progress * 100).toInt();
            statusNotifier.value = '$mbReceived MB / $mbTotal MB ($percent%)';
          }
        },
      );

      // Đóng popup tiến trình tải
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Tự động mở trình cài đặt gói Android của hệ thống (Package Installer)
      final result = await OpenFilex.open(savePath, type: 'application/vnd.android.package-archive');
      if (result.type != ResultType.done && context.mounted) {
        AppToast.show(context, 'Mở gói cài đặt: ${result.message}', icon: Icons.info_outline);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        if (cancelToken.isCancelled) {
          AppToast.show(context, 'Đã hủy tải bản cập nhật');
        } else {
          AppToast.show(context, 'Tải trực tiếp thất bại, chuyển sang trình duyệt');
          final uri = Uri.parse(downloadUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      }
    }
  }
}
