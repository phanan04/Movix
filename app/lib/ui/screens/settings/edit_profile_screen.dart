import 'package:flutter/material.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  String _avatarUrl = '';
  final UserStorage _userStorage = UserStorage();

  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=160',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=160',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=160',
    'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?w=160',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=160',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=160',
  ];

  @override
  void initState() {
    super.initState();
    final user = _userStorage.currentUserNotifier.value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _avatarUrl = user?.avatarUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn ảnh đại diện nhân vật',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn một trong các avatar chuẩn phong cách điện ảnh bên dưới:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _presetAvatars.map((url) {
                  final isSelected = _avatarUrl == url;
                  return InkWell(
                    onTap: () {
                      setState(() => _avatarUrl = url);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(35),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(url),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _onSave() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      AppToast.show(context, 'Tên hiển thị không được để trống!');
      return;
    }

    await _userStorage.updateProfile(
      name: name,
      email: email.isNotEmpty ? email : (_userStorage.currentUserNotifier.value?.email ?? ''),
      avatarUrl: _avatarUrl,
    );

    if (mounted) {
      Navigator.pop(context);
      AppToast.show(context, 'Đã cập nhật thông tin hồ sơ!', icon: Icons.check_circle_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Avatar
              GestureDetector(
                onTap: _showAvatarPicker,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.surfaceLight,
                      backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                      child: _avatarUrl.isEmpty
                          ? const Icon(Icons.person, size: 56, color: AppColors.textSecondary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _showAvatarPicker,
                child: const Text('Đổi ảnh đại diện', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),

              // Inputs
              _buildInputField('Họ và tên / Biệt danh', _nameController, Icons.person_outline),
              const SizedBox(height: 16),
              _buildInputField('Email tài khoản', _emailController, Icons.email_outlined, readOnly: true),
              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text(
                    'Lưu thay đổi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(color: readOnly ? AppColors.textMuted : Colors.white, fontSize: 14),
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.textMuted, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
