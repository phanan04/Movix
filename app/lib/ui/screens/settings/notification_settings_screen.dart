import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _general = true;
  bool _newReleases = true;
  bool _newEpisodes = true;
  bool _recommendations = true;
  bool _appUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSwitchTile('Thông báo chung', 'Bật hoặc tắt tất cả thông báo hệ thống', _general, (v) {
            setState(() => _general = v);
          }),
          const Divider(color: AppColors.border, height: 1),
          _buildSwitchTile('Phim mới phát hành', 'Nhận thông báo khi có phim bom tấn mới', _newReleases, (v) {
            setState(() => _newReleases = v);
          }),
          const Divider(color: AppColors.border, height: 1),
          _buildSwitchTile('Tập mới cập nhật', 'Thông báo ngay khi phim bộ bạn theo dõi có tập mới', _newEpisodes, (v) {
            setState(() => _newEpisodes = v);
          }),
          const Divider(color: AppColors.border, height: 1),
          _buildSwitchTile('Gợi ý phim phù hợp', 'Đề xuất danh sách phim dựa trên lịch sử xem', _recommendations, (v) {
            setState(() => _recommendations = v);
          }),
          const Divider(color: AppColors.border, height: 1),
          _buildSwitchTile('Cập nhật ứng dụng', 'Thông báo tính năng mới và bản vá lỗi', _appUpdates, (v) {
            setState(() => _appUpdates = v);
          }),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
