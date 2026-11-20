import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../auth/create_pin_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometricEnabled = true;
  bool _appLockBackground = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bảo mật & Quyền riêng tư'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildActionTile(
            title: 'Đổi mã PIN bảo mật',
            subtitle: 'Mã PIN 4 số bảo vệ hồ sơ xem phim',
            icon: Icons.pin_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreatePinScreen()),
              );
            },
          ),
          const Divider(color: AppColors.border, height: 1),
          _buildActionTile(
            title: 'Đổi mật khẩu tài khoản',
            subtitle: 'Cập nhật mật khẩu định kỳ để tăng cường an toàn',
            icon: Icons.lock_outline_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mã xác thực đổi mật khẩu đã gửi vào email')),
              );
            },
          ),
          const Divider(color: AppColors.border, height: 1),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 22),
            ),
            title: const Text('Mở khóa sinh trắc học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
            subtitle: const Text('Sử dụng vân tay hoặc Face ID để truy cập nhanh', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: _biometricEnabled,
            activeColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _biometricEnabled = v);
            },
          ),
          const Divider(color: AppColors.border, height: 1),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.security_update_good_rounded, color: AppColors.primary, size: 22),
            ),
            title: const Text('Tự động khóa khi ẩn ứng dụng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
            subtitle: const Text('Yêu cầu mã PIN ngay khi quay lại app', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            value: _appLockBackground,
            activeColor: AppColors.primary,
            onChanged: (v) {
              setState(() => _appLockBackground = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
