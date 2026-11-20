import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  // --- AUTHENTICATION ---
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

  Future<void> signInWithGoogle({
    required String name,
    required String email,
    required String avatarUrl,
  }) async {
    final user = UserModel(
      id: 'google_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      authProvider: 'google',
      isVip: true,
    );
    currentUserNotifier.value = user;
    await _prefs?.setString('user_profile', jsonEncode(user.toJson()));
  }

  Future<void> signInWithEmail({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    final user = UserModel(
      id: 'email_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      avatarUrl: avatarUrl ?? '',
      authProvider: 'email',
      isVip: true,
    );
    currentUserNotifier.value = user;
    await _prefs?.setString('user_profile', jsonEncode(user.toJson()));
  }

  Future<void> signOut() async {
    currentUserNotifier.value = null;
    await _prefs?.remove('user_profile');
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    final current = currentUserNotifier.value;
    final user = UserModel(
      id: current?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      avatarUrl: avatarUrl ?? current?.avatarUrl ?? '',
      authProvider: current?.authProvider ?? 'email',
      isVip: true,
    );
    currentUserNotifier.value = user;
    await _prefs?.setString('user_profile', jsonEncode(user.toJson()));
  }

  // --- MY LIST (Favorites) ---
  void _loadMyList() {
    if (_prefs == null) return;
    final jsonStr = _prefs!.getString('user_my_list');
    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List;
        myListNotifier.value = list.map((e) => MovieItem.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error loading My List: $e');
      }
    }
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
    await _prefs?.setString('user_my_list', jsonEncode(current.map((e) => e.toJson()).toList()));
  }

  // --- WATCH HISTORY & RESUME ---
  void _loadHistory() {
    if (_prefs == null) return;
    final jsonStr = _prefs!.getString('user_history');
    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List;
        historyNotifier.value = list.map((e) => WatchProgress.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error loading Watch History: $e');
      }
    }
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
    await _prefs?.setString('user_history', jsonEncode(current.map((e) => e.toJson()).toList()));
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
