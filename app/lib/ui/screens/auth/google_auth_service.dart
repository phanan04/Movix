import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../main_screen.dart';

class GoogleAuthService {
  static Future<void> showGoogleSignInSheet(BuildContext context) async {
    // Show quick loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        userCredential = await FirebaseAuth.instance.signInWithProvider(googleProvider);
      }

      final User? user = userCredential.user;

      if (user != null) {
        final name = user.displayName ?? (user.email != null ? user.email!.split('@')[0] : 'Thành viên Google');
        final email = user.email ?? 'google_user@gmail.com';
        final avatarUrl = user.photoURL ?? '';

        await UserStorage().signInWithGoogle(
          name: name,
          email: email,
          avatarUrl: avatarUrl,
        );

        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng nhập thành công! Chào mừng $name')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('Google Sign-In Exception: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        String userFriendlyError = 'Lỗi đăng nhập Google: $e';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('unauthorized-domain')) {
          userFriendlyError = 'Tên miền chưa được cấp phép. Bạn hãy truy cập bằng http://localhost:8088 hoặc thêm 127.0.0.1 vào Firebase Authorized Domains.';
        } else if (errStr.contains('popup-blocked')) {
          userFriendlyError = 'Trình duyệt đang chặn popup. Hãy bấm biểu tượng pop-up trên thanh địa chỉ để cho phép.';
        } else if (errStr.contains('popup_closed') || errStr.contains('cancelled') || errStr.contains('canceled')) {
          userFriendlyError = 'Bạn đã đóng cửa sổ đăng nhập Google.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyError),
            backgroundColor: AppColors.surfaceLight,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: AppColors.primary,
              onPressed: () => showGoogleSignInSheet(context),
            ),
          ),
        );
      }
    }
  }
}
