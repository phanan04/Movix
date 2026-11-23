import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/cache/cache_manager.dart';
import 'core/cache/user_storage.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/main_screen.dart';
import 'ui/screens/auth/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tối ưu hóa bộ nhớ đệm hình ảnh (120MB, 400 ảnh) giúp cuộn mượt mà không bị reload
  PaintingBinding.instance.imageCache.maximumSizeBytes = 120 << 20;
  PaintingBinding.instance.imageCache.maximumSize = 400;

  // Khởi động song song Firebase và hệ thống cache để tăng tốc mở app tức thì
  await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).catchError((e) {
      debugPrint('Firebase initialization: $e');
      return Firebase.app();
    }),
    CacheManager().init(),
    UserStorage().init(),
  ]);

  // Khóa cố định màn hình dọc cho điện thoại ngoài Player
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for seamless edge-to-edge dark immersion
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: MovixApp(),
    ),
  );
}

class MovixApp extends StatelessWidget {
  const MovixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movix',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: ValueListenableBuilder<UserModel?>(
        valueListenable: UserStorage().currentUserNotifier,
        builder: (context, user, _) {
          if (user != null) {
            return const MainScreen();
          }
          return const WelcomeScreen();
        },
      ),
    );
  }
}
