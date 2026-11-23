import 'package:flutter/material.dart';
import '../../../../core/cache/user_storage.dart';
import '../../../../core/theme/app_colors.dart';
import 'type_otp_screen.dart';

class ForgotPasswordMethodsScreen extends StatefulWidget {
  const ForgotPasswordMethodsScreen({super.key});

  @override
  State<ForgotPasswordMethodsScreen> createState() => _ForgotPasswordMethodsScreenState();
}

class _ForgotPasswordMethodsScreenState extends State<ForgotPasswordMethodsScreen> {
  final TextEditingController _contactController = TextEditingController();
  String _selectedMethod = 'email'; // 'sms' or 'email'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = UserStorage().currentUserNotifier.value;
    if (user != null && user.email.isNotEmpty) {
      _contactController.text = user.email;
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng nhập ${_selectedMethod == 'email' ? 'địa chỉ Email' : 'số điện thoại'}',
          ),
        ),
      );
      return;
    }

    if (_selectedMethod == 'email') {
      setState(() => _isLoading = true);
      try {
        await UserStorage().sendPasswordResetEmail(contact);
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đã gửi liên kết',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              'Đường link đặt lại mật khẩu đã được gửi tới hộp thư:\n$contact\n\nVui lòng kiểm tra hộp thư đến (hoặc hòm thư Rác / Spam) và làm theo hướng dẫn để thiết lập mật khẩu mới.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Về trang Đăng nhập', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(e.toString()),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TypeOtpScreen(
            targetContact: contact,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Chọn phương thức nhận mã',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng chọn phương thức và nhập thông tin liên hệ để nhận mã OTP xác thực khôi phục mật khẩu.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              // SMS Card
              _buildMethodCard(
                id: 'sms',
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Gửi mã qua tin nhắn SMS',
                subtitle: 'Nhận OTP 4 chữ số qua số điện thoại',
              ),
              const SizedBox(height: 14),

              // Email Card
              _buildMethodCard(
                id: 'email',
                icon: Icons.email_outlined,
                title: 'Gửi mã qua địa chỉ Email',
                subtitle: 'Nhận OTP 4 chữ số qua hộp thư điện tử',
              ),
              const SizedBox(height: 20),

              // Real Contact Input Field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _contactController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  keyboardType: _selectedMethod == 'email' ? TextInputType.emailAddress : TextInputType.phone,
                  decoration: InputDecoration(
                    icon: Icon(
                      _selectedMethod == 'email' ? Icons.email_outlined : Icons.phone_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    hintText: _selectedMethod == 'email' ? 'Nhập email của bạn (vd: your@gmail.com)' : 'Nhập số điện thoại (vd: 0912345678)',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _selectedMethod == 'email' ? 'Gửi liên kết khôi phục' : 'Tiếp tục gửi mã OTP',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedMethod == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
