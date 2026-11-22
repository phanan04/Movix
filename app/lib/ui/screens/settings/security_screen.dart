import 'package:flutter/material.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_toast.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final UserStorage _userStorage = UserStorage();

  void _showChangePasswordDialog() {
    final user = _userStorage.currentUserNotifier.value;
    if (user == null) {
      AppToast.show(context, 'Vui lòng đăng nhập để đổi mật khẩu', icon: Icons.lock_outline_rounded);
      return;
    }
    if (user.authProvider == 'google') {
      AppToast.show(context, 'Tài khoản Google được bảo mật trực tiếp bởi Google, không có mật khẩu riêng', icon: Icons.info_outline);
      return;
    }

    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isObscured = true;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text('Đổi mật khẩu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorText != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          errorText!,
                          style: const TextStyle(color: AppColors.primary, fontSize: 12.5),
                        ),
                      ),
                    ],
                    TextField(
                      controller: oldPassController,
                      obscureText: isObscured,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu hiện tại',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPassController,
                      obscureText: isObscured,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassController,
                      obscureText: isObscured,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: !isObscured,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setModalState(() => isObscured = !isObscured);
                          },
                        ),
                        const Text('Hiện mật khẩu', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final oldPass = oldPassController.text;
                    final newPass = newPassController.text;
                    final confirmPass = confirmPassController.text;

                    if (oldPass.isEmpty || newPass.isEmpty) {
                      setModalState(() => errorText = 'Vui lòng nhập đầy đủ các trường mật khẩu!');
                      return;
                    }
                    if (newPass.length < 6) {
                      setModalState(() => errorText = 'Mật khẩu mới phải có tối thiểu 6 ký tự!');
                      return;
                    }
                    if (newPass != confirmPass) {
                      setModalState(() => errorText = 'Mật khẩu mới và xác nhận mật khẩu không trùng khớp!');
                      return;
                    }

                    try {
                      await _userStorage.changePassword(oldPassword: oldPass, newPassword: newPass);
                      if (context.mounted) {
                        Navigator.pop(dialogCtx);
                        AppToast.show(context, 'Đổi mật khẩu thành công!', icon: Icons.check_circle_rounded);
                      }
                    } catch (e) {
                      setModalState(() => errorText = e.toString());
                    }
                  },
                  child: const Text('Cập nhật', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa lịch sử xem?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text(
          'Toàn bộ lịch sử các tập phim đang xem dở sẽ được dọn dẹp sạch sẽ. Bạn có chắc chắn muốn xóa?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              await _userStorage.clearWatchHistory();
              if (mounted) {
                AppToast.show(context, 'Đã xóa sạch lịch sử xem phim', icon: Icons.delete_outline_rounded);
              }
            },
            child: const Text('Xóa ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmClearMyList() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa danh sách yêu thích?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text(
          'Tất cả các bộ phim bạn đã lưu trong mục "Danh sách của tôi" sẽ bị xóa. Bạn có chắc chắn?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              await _userStorage.clearMyList();
              if (mounted) {
                AppToast.show(context, 'Đã xóa toàn bộ phim yêu thích', icon: Icons.bookmark_remove_rounded);
              }
            },
            child: const Text('Xóa ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bảo mật & Dữ liệu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Tài khoản & Xác thực',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          _buildActionTile(
            title: 'Đổi mật khẩu tài khoản',
            subtitle: 'Xác minh mật khẩu cũ và tạo mật khẩu mới an toàn',
            icon: Icons.lock_outline_rounded,
            onTap: _showChangePasswordDialog,
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Quản lý dữ liệu cá nhân',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          _buildActionTile(
            title: 'Xóa lịch sử xem phim',
            subtitle: 'Xóa toàn bộ các phim và tập đang xem dở trên tài khoản này',
            icon: Icons.history_rounded,
            isDestructive: true,
            onTap: _confirmClearHistory,
          ),
          const Divider(color: AppColors.border, height: 1),
          _buildActionTile(
            title: 'Xóa danh sách yêu thích',
            subtitle: 'Xóa toàn bộ các phim đã lưu trong mục My List',
            icon: Icons.bookmark_border_rounded,
            isDestructive: true,
            onTap: _confirmClearMyList,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? AppColors.primaryMuted : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDestructive ? AppColors.primary : AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isDestructive ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
