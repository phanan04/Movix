import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../main_screen.dart';
import 'sign_in_screen.dart';

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
        Navigator.pop(context); // Close loading dialog

        // Show a polished, user-friendly modal with fallback options
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (modalCtx) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.lock_person_outlined, color: AppColors.primary, size: 28),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Đăng nhập tài khoản',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tính năng đăng nhập nhanh qua Google hiện chưa được kích hoạt trên bản cài đặt này.\n\nBạn có thể đăng nhập bằng Email & Mật khẩu hoặc bấm "Trải nghiệm ngay" để thưởng thức phim tức thì!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Option 1: Login with Email
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.email_outlined, color: Colors.white, size: 20),
                        label: const Text(
                          'Đăng nhập bằng Email & Mật khẩu',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignInScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Option 2: Guest VIP
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Trải nghiệm ngay (Khách VIP)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () async {
                          Navigator.pop(modalCtx);
                          await UserStorage().loginAsGuest();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const MainScreen()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    }
  }
}
