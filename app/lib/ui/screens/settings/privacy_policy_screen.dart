import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chính sách quyền riêng tư'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Cam kết bảo mật thông tin',
              'Movix cam kết tôn trọng và bảo vệ tối đa quyền riêng tư của mọi người dùng. Mọi thông tin cá nhân của bạn đều được mã hóa theo tiêu chuẩn quốc tế và không bao giờ chia sẻ cho bất kỳ bên thứ ba nào.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              '2. Dữ liệu chúng tôi thu thập',
              'Chúng tôi chỉ lưu trữ cục bộ trên thiết bị của bạn: lịch sử xem phim, danh sách phim yêu thích (My List), vị trí phút xem dở dang và mã PIN bảo mật nhằm mục đích tối ưu trải nghiệm xem phim.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              '3. Tối ưu hiệu năng và Cache',
              'Ứng dụng lưu ảnh bìa và dữ liệu danh mục trong bộ nhớ đệm (Cache) của máy để đảm bảo tốc độ mở phim tức thì. Bạn có toàn quyền xóa dữ liệu này bất cứ lúc nào tại mục "Dọn dẹp bộ nhớ đệm".',
            ),
            const SizedBox(height: 16),
            _buildSection(
              '4. Quyền của người dùng',
              'Bạn có quyền cập nhật, chỉnh sửa hồ sơ hoặc yêu cầu xóa toàn bộ dữ liệu lịch sử và tài khoản khỏi hệ thống của Movix bất kỳ lúc nào.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
