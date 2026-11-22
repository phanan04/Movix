import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String authProvider;
  final bool isVip;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.authProvider,
    this.isVip = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'authProvider': authProvider,
    'isVip': isVip,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Thành viên Movix',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      authProvider: json['authProvider']?.toString() ?? 'email',
      isVip: json['isVip'] == true,
    );
  }
}

class UserCommentItem {
  final String id;
  final String movieSlug;
  final String userName;
  final String userAvatar;
  final String content;
  final String timeText;
  int likes;
  bool isLiked;

  UserCommentItem({
    required this.id,
    required this.movieSlug,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.timeText,
    this.likes = 0,
    this.isLiked = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'movieSlug': movieSlug,
    'userName': userName,
    'userAvatar': userAvatar,
    'content': content,
    'timeText': timeText,
    'likes': likes,
    'isLiked': isLiked,
  };

  factory UserCommentItem.fromJson(Map<String, dynamic> json) {
    return UserCommentItem(
      id: json['id']?.toString() ?? '',
      movieSlug: json['movieSlug']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Người dùng',
      userAvatar: json['userAvatar']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      timeText: json['timeText']?.toString() ?? 'Vừa xong',
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] == true,
    );
  }
}

class WatchProgress {
  final String movieSlug;
  final String movieName;
  final String posterUrl;
  final String episodeName;
  final String episodeSlug;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime updatedAt;

  WatchProgress({
    required this.movieSlug,
    required this.movieName,
    required this.posterUrl,
    required this.episodeName,
    required this.episodeSlug,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.updatedAt,
  });

  double get progressPercentage {
    if (durationSeconds <= 0) return 0.0;
    return (positionSeconds / durationSeconds).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'movieSlug': movieSlug,
    'movieName': movieName,
    'posterUrl': posterUrl,
    'episodeName': episodeName,
    'episodeSlug': episodeSlug,
    'positionSeconds': positionSeconds,
    'durationSeconds': durationSeconds,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WatchProgress.fromJson(Map<String, dynamic> json) {
    return WatchProgress(
      movieSlug: json['movieSlug']?.toString() ?? '',
      movieName: json['movieName']?.toString() ?? '',
      posterUrl: json['posterUrl']?.toString() ?? '',
      episodeName: json['episodeName']?.toString() ?? '',
      episodeSlug: json['episodeSlug']?.toString() ?? '',
      positionSeconds: (json['positionSeconds'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class UserStorage {
  static final UserStorage _instance = UserStorage._internal();
  factory UserStorage() => _instance;
  UserStorage._internal();

  SharedPreferences? _prefs;

  final ValueNotifier<UserModel?> currentUserNotifier = ValueNotifier(null);
  final ValueNotifier<List<MovieItem>> myListNotifier = ValueNotifier([]);
  final ValueNotifier<List<WatchProgress>> historyNotifier = ValueNotifier([]);
  final ValueNotifier<List<UserCommentItem>> commentsNotifier = ValueNotifier([]);

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _loadUser();
    _loadMyList();
    _loadHistory();
    _loadComments();
  }

  // --- SCOPED STORAGE KEYS (Data Isolation per User) ---
  String _getMyListKey() {
    final user = currentUserNotifier.value;
    if (user == null) return 'guest_my_list';
    final clean = (user.email.isNotEmpty ? user.email : user.id).toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    return 'user_${clean}_my_list';
  }

  String _getHistoryKey() {
    final user = currentUserNotifier.value;
    if (user == null) return 'guest_history';
    final clean = (user.email.isNotEmpty ? user.email : user.id).toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    return 'user_${clean}_history';
  }

  void _switchUserDataContext(UserModel? user) {
    if (user == null) {
      myListNotifier.value = [];
      historyNotifier.value = [];
    } else {
      _loadMyList();
      _loadHistory();
    }
  }

  // --- LOCAL ACCOUNTS DATABASE (For verified offline / local fallback) ---
  Map<String, dynamic> _getRegisteredAccounts() {
    if (_prefs == null) return {};
    final raw = _prefs!.getString('app_registered_accounts');
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      debugPrint('Error decoding registered accounts: $e');
    }
    return {};
  }

  Future<void> _saveRegisteredAccounts(Map<String, dynamic> accounts) async {
    await _prefs?.setString('app_registered_accounts', jsonEncode(accounts));
  }

  // --- AUTHENTICATION & REGISTRATION ---
  void _loadUser() {
    if (_prefs == null) return;
    final jsonStr = _prefs!.getString('user_profile');
    if (jsonStr != null) {
      try {
        currentUserNotifier.value = UserModel.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        debugPrint('Error loading user profile: $e');
      }
    }
  }

  Future<void> _setActiveUser(UserModel user) async {
    currentUserNotifier.value = user;
    await _prefs?.setString('user_profile', jsonEncode(user.toJson()));
    _switchUserDataContext(user);
  }

  /// Real Account Registration with Password and Email Validation
  Future<UserModel> registerAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedName = name.trim();

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedEmail)) {
      throw 'Định dạng email không hợp lệ. Vui lòng nhập đúng email (VD: abc@gmail.com)';
    }
    if (password.length < 6) {
      throw 'Mật khẩu phải có độ dài tối thiểu 6 ký tự!';
    }
    if (trimmedName.isEmpty) {
      throw 'Vui lòng nhập tên người dùng!';
    }

    UserModel? createdUser;

    // 1. Attempt Firebase Auth registration
    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      if (userCred.user != null) {
        await userCred.user!.updateDisplayName(trimmedName);
        createdUser = UserModel(
          id: userCred.user!.uid,
          name: trimmedName,
          email: trimmedEmail,
          avatarUrl: '',
          authProvider: 'firebase_email',
          isVip: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'Email này đã được đăng ký tài khoản. Vui lòng chọn Đăng nhập!';
      } else if (e.code == 'weak-password') {
        throw 'Mật khẩu quá yếu. Vui lòng đặt mật khẩu phức tạp hơn!';
      } else if (e.code == 'invalid-email') {
        throw 'Định dạng email không hợp lệ!';
      }
      debugPrint('Firebase registration bypassed/fallback: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('General auth error: $e');
    }

    // 2. Validate against local persistent account registry
    final accounts = _getRegisteredAccounts();
    if (accounts.containsKey(trimmedEmail)) {
      throw 'Email này đã được đăng ký tài khoản trên hệ thống. Vui lòng đăng nhập!';
    }

    createdUser ??= UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      email: trimmedEmail,
      avatarUrl: '',
      authProvider: 'local_email',
      isVip: true,
    );

    // Save into registered accounts registry
    accounts[trimmedEmail] = {
      'id': createdUser.id,
      'name': createdUser.name,
      'email': trimmedEmail,
      'password': password,
      'avatarUrl': createdUser.avatarUrl,
      'authProvider': createdUser.authProvider,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _saveRegisteredAccounts(accounts);
    await _setActiveUser(createdUser);
    return createdUser;
  }

  /// Real Account Login with Password Verification
  Future<UserModel> loginAccount({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw 'Vui lòng nhập đầy đủ Email và Mật khẩu!';
    }

    UserModel? loggedInUser;

    // 1. Attempt Firebase Auth Login
    try {
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      if (userCred.user != null) {
        final u = userCred.user!;
        loggedInUser = UserModel(
          id: u.uid,
          name: (u.displayName != null && u.displayName!.isNotEmpty) ? u.displayName! : trimmedEmail.split('@')[0],
          email: trimmedEmail,
          avatarUrl: u.photoURL ?? '',
          authProvider: 'firebase_email',
          isVip: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Mật khẩu không chính xác! Vui lòng thử lại.';
      } else if (e.code == 'user-disabled') {
        throw 'Tài khoản này đã bị khóa.';
      } else if (e.code == 'invalid-email') {
        throw 'Định dạng email không hợp lệ!';
      }
      debugPrint('Firebase login fallback to local database: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('Firebase general login exception: $e');
    }

    // 2. If Firebase login succeeded, sync local record & set active
    if (loggedInUser != null) {
      final accounts = _getRegisteredAccounts();
      accounts[trimmedEmail] = {
        'id': loggedInUser.id,
        'name': loggedInUser.name,
        'email': trimmedEmail,
        'password': password,
        'avatarUrl': loggedInUser.avatarUrl,
        'authProvider': 'firebase_email',
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _saveRegisteredAccounts(accounts);
      await _setActiveUser(loggedInUser);
      return loggedInUser;
    }

    // 3. Fallback to Local Persistent Account Registry
    final accounts = _getRegisteredAccounts();
    if (!accounts.containsKey(trimmedEmail)) {
      throw 'Tài khoản không tồn tại. Vui lòng kiểm tra lại email hoặc bấm Đăng ký tài khoản mới!';
    }

    final record = accounts[trimmedEmail] as Map<String, dynamic>;
    final storedPassword = record['password']?.toString() ?? '';
    if (storedPassword != password) {
      throw 'Mật khẩu không chính xác! Vui lòng thử lại.';
    }

    loggedInUser = UserModel(
      id: record['id']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: record['name']?.toString() ?? trimmedEmail.split('@')[0],
      email: trimmedEmail,
      avatarUrl: record['avatarUrl']?.toString() ?? '',
      authProvider: record['authProvider']?.toString() ?? 'email',
      isVip: true,
    );

    await _setActiveUser(loggedInUser);
    return loggedInUser;
  }

  Future<void> signInWithGoogle({
    required String id,
    required String name,
    required String email,
    required String avatarUrl,
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    final user = UserModel(
      id: id.isNotEmpty ? id : 'google_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      name: name.isNotEmpty ? name : cleanEmail.split('@')[0],
      email: cleanEmail,
      avatarUrl: avatarUrl,
      authProvider: 'google',
      isVip: true,
    );

    final accounts = _getRegisteredAccounts();
    accounts[cleanEmail] = {
      'id': user.id,
      'name': user.name,
      'email': cleanEmail,
      'password': 'google_oauth_authorized',
      'avatarUrl': user.avatarUrl,
      'authProvider': 'google',
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _saveRegisteredAccounts(accounts);
    await _setActiveUser(user);
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    currentUserNotifier.value = null;
    await _prefs?.remove('user_profile');
    _switchUserDataContext(null);
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    final current = currentUserNotifier.value;
    final user = UserModel(
      id: current?.id ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      avatarUrl: avatarUrl ?? current?.avatarUrl ?? '',
      authProvider: current?.authProvider ?? 'email',
      isVip: true,
    );
    await _setActiveUser(user);
  }

  // --- MY LIST (Favorites - Per Account Scoped) ---
  void _loadMyList() {
    if (_prefs == null) return;
    final key = _getMyListKey();
    var jsonStr = _prefs!.getString(key);

    // Migration fallback for existing data from legacy 'user_my_list'
    if (jsonStr == null && currentUserNotifier.value != null) {
      jsonStr = _prefs!.getString('user_my_list');
      if (jsonStr != null) {
        _prefs!.setString(key, jsonStr);
      }
    }

    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List;
        myListNotifier.value = list.map((e) => MovieItem.fromJson(e)).toList();
        return;
      } catch (e) {
        debugPrint('Error loading My List: $e');
      }
    }
    myListNotifier.value = [];
  }

  bool isInMyList(String slug) {
    return myListNotifier.value.any((m) => m.slug == slug);
  }

  Future<void> toggleMyList(MovieItem movie) async {
    final current = List<MovieItem>.from(myListNotifier.value);
    final idx = current.indexWhere((m) => m.slug == movie.slug);
    if (idx >= 0) {
      current.removeAt(idx);
    } else {
      current.insert(0, movie);
    }
    myListNotifier.value = current;
    final key = _getMyListKey();
    await _prefs?.setString(key, jsonEncode(current.map((e) => e.toJson()).toList()));
  }

  // --- WATCH HISTORY & RESUME (Per Account Scoped) ---
  void _loadHistory() {
    if (_prefs == null) return;
    final key = _getHistoryKey();
    var jsonStr = _prefs!.getString(key);

    // Migration fallback for existing data from legacy 'user_history'
    if (jsonStr == null && currentUserNotifier.value != null) {
      jsonStr = _prefs!.getString('user_history');
      if (jsonStr != null) {
        _prefs!.setString(key, jsonStr);
      }
    }

    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List;
        historyNotifier.value = list.map((e) => WatchProgress.fromJson(e)).toList();
        return;
      } catch (e) {
        debugPrint('Error loading Watch History: $e');
      }
    }
    historyNotifier.value = [];
  }

  WatchProgress? getProgress(String movieSlug) {
    return historyNotifier.value.cast<WatchProgress?>().firstWhere(
      (h) => h?.movieSlug == movieSlug,
      orElse: () => null,
    );
  }

  Future<void> saveProgress(WatchProgress progress) async {
    final current = List<WatchProgress>.from(historyNotifier.value);
    current.removeWhere((h) => h.movieSlug == progress.movieSlug);
    current.insert(0, progress);
    if (current.length > 50) current.removeLast();

    historyNotifier.value = current;
    final key = _getHistoryKey();
    await _prefs?.setString(key, jsonEncode(current.map((e) => e.toJson()).toList()));
  }

  // --- REAL COMMENTS PERSISTENCE ---
  void _loadComments() {
    if (_prefs == null) return;
    final jsonStr = _prefs!.getString('user_comments');
    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List;
        commentsNotifier.value = list.map((e) => UserCommentItem.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error loading comments: $e');
      }
    }
  }

  List<UserCommentItem> getCommentsForMovie(String movieSlug) {
    return commentsNotifier.value.where((c) => c.movieSlug == movieSlug).toList();
  }

  Future<void> addComment({
    required String movieSlug,
    required String content,
  }) async {
    final user = currentUserNotifier.value;
    final newComment = UserCommentItem(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      movieSlug: movieSlug,
      userName: user != null && user.name.isNotEmpty ? user.name : 'Khán giả Movix',
      userAvatar: user != null ? user.avatarUrl : '',
      content: content,
      timeText: 'Vừa xong',
      likes: 0,
    );

    final current = List<UserCommentItem>.from(commentsNotifier.value);
    current.insert(0, newComment);
    commentsNotifier.value = current;
    await _prefs?.setString('user_comments', jsonEncode(current.map((e) => e.toJson()).toList()));
  }
}
