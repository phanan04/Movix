import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../main_screen.dart';

class GoogleAuthService {
  static bool _isGoogleSignInInitialized = false;

  static Future<void> _ensureInitialized() async {
    if (!_isGoogleSignInInitialized && !kIsWeb) {
      try {
        await GoogleSignIn.instance.initialize();
        _isGoogleSignInInitialized = true;
      } catch (e) {
        debugPrint('GoogleSignIn.instance.initialize error: $e');
      }
    }
  }

  static Future<void> showGoogleSignInSheet(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      if (kIsWeb) {
        // --- WEB GOOGLE SIGN-IN ---
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        final User? user = userCredential.user;

        if (user != null) {
          final name = user.displayName ?? (user.email != null ? user.email!.split('@')[0] : 'Thành viên Google');
          final email = user.email ?? 'google_user@gmail.com';
          final avatarUrl = user.photoURL ?? '';

          await UserStorage().signInWithGoogle(
            id: user.uid,
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
      } else {
        // --- MOBILE (ANDROID / IOS) GOOGLE SIGN-IN ---
        await _ensureInitialized();

        final GoogleSignInAccount googleAccount = await GoogleSignIn.instance.authenticate();

        String userId = 'google_${googleAccount.id}';
        String name = googleAccount.displayName ?? googleAccount.email.split('@')[0];
        String email = googleAccount.email;
        String avatarUrl = googleAccount.photoUrl ?? '';

        // Attempt linking with Firebase Auth Credential if available
        try {
          final idToken = googleAccount.authentication.idToken;
          if (idToken != null && idToken.isNotEmpty) {
            final AuthCredential credential = GoogleAuthProvider.credential(
              idToken: idToken,
            );
            final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            if (userCredential.user != null) {
              userId = userCredential.user!.uid;
              name = userCredential.user!.displayName ?? name;
              email = userCredential.user!.email ?? email;
              avatarUrl = userCredential.user!.photoURL ?? avatarUrl;
            }
          }
        } catch (firebaseErr) {
          debugPrint('Firebase link warning (using GoogleSignIn verified account directly): $firebaseErr');
        }

        await UserStorage().signInWithGoogle(
          id: userId,
          name: name,
          email: email,
          avatarUrl: avatarUrl,
        );

        if (context.mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng nhập Google thành công! Chào mừng $name')),
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

        if (errStr.contains('10') || errStr.contains('developer_error')) {
          userFriendlyError = 'Dịch vụ Google Sign-In yêu cầu mã SHA-1 trên Firebase Console. Bạn vui lòng sử dụng Đăng nhập bằng Email & Mật khẩu bên dưới.';
        } else if (errStr.contains('unauthorized-domain')) {
          userFriendlyError = 'Tên miền chưa được cấp phép. Bạn hãy truy cập bằng http://localhost:8088 hoặc thêm 127.0.0.1 vào Firebase Authorized Domains.';
        } else if (errStr.contains('popup-blocked')) {
          userFriendlyError = 'Trình duyệt đang chặn popup. Hãy bấm biểu tượng pop-up trên thanh địa chỉ để cho phép.';
        } else if (errStr.contains('popup_closed') || errStr.contains('canceled') || errStr.contains('cancelled') || errStr.contains('network_error')) {
          userFriendlyError = 'Bạn đã hủy đăng nhập Google hoặc kết nối mạng bị gián đoạn.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFriendlyError),
            backgroundColor: AppColors.surfaceLight,
            duration: const Duration(seconds: 6),
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
