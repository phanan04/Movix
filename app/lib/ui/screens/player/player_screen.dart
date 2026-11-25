import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:popover/popover.dart';
import 'package:video_player/video_player.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/models/movie_model.dart';
import '../../../core/network/ping_helper.dart';
import '../../../core/theme/app_colors.dart';
import 'web_player_controller.dart';

enum AspectRatioMode {
  fit169,
  fillScreen,
  zoomCinematic,
}

class PlayerScreen extends StatefulWidget {
  final MovieDetail movie;
  final EpisodeItem episode;
  final List<EpisodeItem> allEpisodes;
  final int initialPositionSeconds;

  const PlayerScreen({
    super.key,
    required this.movie,
    required this.episode,
    required this.allEpisodes,
    this.initialPositionSeconds = 0,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late EpisodeItem _currentEpisode;
  VideoPlayerController? _nativeController;
  late String _webPlayerId;
  final GlobalKey _videoPlayerKey = GlobalKey();

  // Multi-source Streaming & Server Management
  late int _selectedServerIndex;
  late List<EpisodeItem> _currentEpisodeList;
  final Map<int, int> _serverLatencies = {};
  final Set<int> _pingingServers = {};

  final bool _isWebMode = kIsWeb;
  bool _isPlaying = true;
  bool _isLocked = false;
  bool _showControls = true;
  bool _isLongPressing2X = false;
  bool _isFullScreen = false;
  double _currentSpeed = 1.0;
  AspectRatioMode _aspectRatioMode = AspectRatioMode.fit169;

  // 2-Finger Pinch to Zoom & Pan Offset
  double _customScale = 1.0;
  double _baseScale = 1.0;
  Offset _customOffset = Offset.zero;
  Offset _lastFocalPoint = Offset.zero;

  String get _aspectRatioLabel {
    if (_customScale > 1.05) {
      return '${(_customScale * 100).round()}%';
    }
    switch (_aspectRatioMode) {
      case AspectRatioMode.fit169:
        return '16:9 Gốc';
      case AspectRatioMode.fillScreen:
        return 'Tràn viền';
      case AspectRatioMode.zoomCinematic:
        return 'Zoom';
    }
  }

  String _selectedQuality = '1080p FHD';
  String _selectedAudioTrack = 'Tiếng gốc (Vietsub)';
  bool _autoPlayNext = true;
  bool _enableSkipIntro = true;
  double _volume = 1.0;
  bool _isMuted = false;

  double _currentPosition = 0;
  double _totalDuration = 0;
  bool _isDraggingSlider = false;

  // Netflix Episodes slide-in drawer on landscape / TV
  bool _showEpisodeDrawer = false;
  int _drawerChunkIndex = 0;

  // Floating HUD Toast message
  String? _hudToastMessage;
  Timer? _hudToastTimer;

  // Double tap animation states
  bool _showLeftSeekRipple = false;
  bool _showRightSeekRipple = false;
  Timer? _leftRippleTimer;
  Timer? _rightRippleTimer;

  Timer? _controlsTimer;
  Timer? _tickerTimer;
  Timer? _progressSaveTimer;
  final UserStorage _userStorage = UserStorage();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.episode;
    _currentPosition = widget.initialPositionSeconds.toDouble();

    // Khởi tạo máy chủ phát hiện tại
    _selectedServerIndex = 0;
    if (widget.movie.episodes.isNotEmpty) {
      final sIdx = widget.movie.episodes.indexWhere(
        (s) => s.serverData.any((e) => e.slug == widget.episode.slug || (e.linkM3u8.isNotEmpty && e.linkM3u8 == widget.episode.linkM3u8)),
      );
      if (sIdx != -1) {
        _selectedServerIndex = sIdx;
      }
      _currentEpisodeList = widget.movie.episodes[_selectedServerIndex].serverData;
    } else {
      _currentEpisodeList = widget.allEpisodes;
    }

    _webPlayerId = 'movix_player_${_currentEpisode.slug}_${DateTime.now().millisecondsSinceEpoch % 100000}';
    _startPlaying();

    // Đo độ trễ thực ms đến tất cả máy chủ phát (KKPhim, VSMov,...)
    _measureAllServerLatencies();

    // Luôn khóa xoay ngang toàn màn hình (Landscape) khi mở Player
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    // Auto calculate initial episode chunk for the drawer
    const chunkSize = 20;
    final curIdx = _currentEpisodeList.indexWhere((e) => e.slug == _currentEpisode.slug);
    if (curIdx >= 0) {
      _drawerChunkIndex = curIdx ~/ chunkSize;
    }

    // Sync position every 500ms (chỉ rebuild UI khi controls đang hiện và giá trị đổi)
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _syncPlaybackState());

    // Auto save progress every 5 seconds
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveProgress());
  }

  void _showHudToast(String msg) {
    _hudToastTimer?.cancel();
    setState(() => _hudToastMessage = msg);
    _hudToastTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _hudToastMessage = null);
    });
  }

  void _setVolume(double val) {
    setState(() {
      _volume = val.clamp(0.0, 1.0);
      _isMuted = (_volume == 0.0);
    });
    if (_isWebMode) {
      webSetVolume(_webPlayerId, _isMuted ? 0.0 : _volume);
    } else {
      _nativeController?.setVolume(_isMuted ? 0.0 : _volume);
    }
    _showHudToast('Âm lượng: ${(_volume * 100).round()}%');
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isWebMode) {
      webSetVolume(_webPlayerId, _isMuted ? 0.0 : _volume);
    } else {
      _nativeController?.setVolume(_isMuted ? 0.0 : _volume);
    }
    _showHudToast(_isMuted ? 'Đã tắt tiếng' : 'Âm lượng: ${(_volume * 100).round()}%');
  }

  void _startPlaying() {
    if (_isWebMode) {
      webPlay(_webPlayerId);
    } else {
      _initNativePlayer(_currentEpisode.linkM3u8);
    }
    _resetControlsTimer();
  }

  Future<void> _initNativePlayer(String url) async {
    await _nativeController?.dispose();
    _nativeController = null;

    if (url.isEmpty) return;

    try {
      final c = VideoPlayerController.networkUrl(
        Uri.parse(url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _nativeController = c;
      await c.initialize();
      if (widget.initialPositionSeconds > 0) {
        await c.seekTo(Duration(seconds: widget.initialPositionSeconds));
      }
      await c.play();
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _totalDuration = c.value.duration.inSeconds.toDouble();
        });
      }
    } catch (e) {
      debugPrint('Native player error: $e');
      _showHudToast('Lỗi tải video, vui lòng thử lại.');
    }
  }

  void _syncPlaybackState() {
    if (!mounted || _isDraggingSlider) return;

    double pos = _currentPosition;
    double dur = _totalDuration;
    bool playing = _isPlaying;

    if (_isWebMode) {
      pos = webGetCurrentTime(_webPlayerId);
      final webDur = webGetDuration(_webPlayerId);
      if (webDur > 0) dur = webDur;
      playing = webIsPlaying(_webPlayerId);
    } else if (_nativeController != null && _nativeController!.value.isInitialized) {
      pos = _nativeController!.value.position.inSeconds.toDouble();
      dur = _nativeController!.value.duration.inSeconds.toDouble();
      playing = _nativeController!.value.isPlaying;
    } else {
      return;
    }

    final changed = pos.round() != _currentPosition.round() ||
        dur.round() != _totalDuration.round() ||
        playing != _isPlaying;

    _currentPosition = pos;
    _totalDuration = dur;
    _isPlaying = playing;

    if (_showControls && changed) {
      setState(() {});
    }
  }

  void _saveProgress() {
    final pos = _currentPosition.round();
    final dur = _totalDuration.round();
    if (dur > 0 && pos > 0) {
      _userStorage.saveProgress(
        WatchProgress(
          movieSlug: widget.movie.slug,
          movieName: widget.movie.name,
          posterUrl: widget.movie.fullPosterUrl,
          episodeName: _currentEpisode.name,
          episodeSlug: _currentEpisode.slug,
          positionSeconds: pos,
          durationSeconds: dur,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  // --- FULLSCREEN TOGGLE ---
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isWebMode) {
      webToggleFullscreen();
    } else {
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }

    _resetControlsTimer();
    _showHudToast(_isFullScreen ? 'Toàn màn hình' : 'Đã thoát toàn màn hình');
  }

  // --- YOUTUBE GESTURES ---

  void _onDoubleTapLeft() {
    if (_isLocked) return;
    _seekRelative(-10);

    setState(() {
      _showLeftSeekRipple = true;
    });
    _leftRippleTimer?.cancel();
    _leftRippleTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showLeftSeekRipple = false);
    });
    _resetControlsTimer();
  }

  void _onDoubleTapRight() {
    if (_isLocked) return;
    _seekRelative(10);

    setState(() {
      _showRightSeekRipple = true;
    });
    _rightRippleTimer?.cancel();
    _rightRippleTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showRightSeekRipple = false);
    });
    _resetControlsTimer();
  }

  void _onLongPressStart() {
    if (_isLocked) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isLongPressing2X = true;
    });
    _setPlaybackSpeed(2.0);
  }

  void _onLongPressEnd() {
    if (!_isLongPressing2X) return;
    setState(() {
      _isLongPressing2X = false;
    });
    _setPlaybackSpeed(_currentSpeed);
  }

  // --- CỬ CHỈ 2 NGÓN TAY: PINCH-TO-ZOOM & PAN KÉO NÂNG PHỤ ĐỀ ---
  void _onPinchScaleStart(ScaleStartDetails details) {
    if (_isLocked) return;
    _baseScale = _customScale;
    _lastFocalPoint = details.focalPoint;
  }

  void _onPinchScaleUpdate(ScaleUpdateDetails details) {
    if (_isLocked) return;
    if (details.pointerCount >= 2) {
      // 2 ngón tay chụm lại hoặc banh ra: Phóng to / Thu nhỏ tùy thích
      final newScale = (_baseScale * details.scale).clamp(1.0, 3.5);
      final delta = details.focalPoint - _lastFocalPoint;
      _lastFocalPoint = details.focalPoint;

      setState(() {
        _customScale = newScale;
        if (_customScale > 1.0) {
          final size = MediaQuery.of(context).size;
          final maxPanX = (size.width * (_customScale - 1.0)) / 2;
          final maxPanY = (size.height * (_customScale - 1.0)) / 2;
          _customOffset = Offset(
            (_customOffset.dx + delta.dx).clamp(-maxPanX, maxPanX),
            (_customOffset.dy + delta.dy).clamp(-maxPanY, maxPanY),
          );
        } else {
          _customOffset = Offset.zero;
        }
      });
      _showHudToast('Thu phóng: ${(_customScale * 100).round()}%');
      _resetControlsTimer();
    } else if (_customScale > 1.05) {
      // Khi đã phóng to: Cho phép dùng 1 ngón tay vuốt trượt để dịch chuyển phụ đề lên/xuống vừa tầm mắt
      final delta = details.focalPoint - _lastFocalPoint;
      _lastFocalPoint = details.focalPoint;

      setState(() {
        final size = MediaQuery.of(context).size;
        final maxPanX = (size.width * (_customScale - 1.0)) / 2;
        final maxPanY = (size.height * (_customScale - 1.0)) / 2;
        _customOffset = Offset(
          (_customOffset.dx + delta.dx).clamp(-maxPanX, maxPanX),
          (_customOffset.dy + delta.dy).clamp(-maxPanY, maxPanY),
        );
      });
    }
  }

  void _onPinchScaleEnd(ScaleEndDetails details) {
    if (_customScale < 1.03) {
      setState(() {
        _customScale = 1.0;
        _customOffset = Offset.zero;
      });
    }
  }

  void _resetPinchZoom() {
    setState(() {
      _customScale = 1.0;
      _customOffset = Offset.zero;
    });
    _showHudToast('Đã đặt lại tỷ lệ');
  }

  void _seekRelative(double seconds) {
    if (_isWebMode) {
      webSeekRelative(_webPlayerId, seconds);
      setState(() {
        _currentPosition = (_currentPosition + seconds).clamp(0.0, _totalDuration > 0 ? _totalDuration : 99999.0);
      });
    } else if (_nativeController != null) {
      final target = Duration(seconds: (_currentPosition + seconds).round());
      _nativeController!.seekTo(target);
    }
  }

  void _seekTo(double seconds) {
    if (_isWebMode) {
      webSeekTo(_webPlayerId, seconds);
      setState(() {
        _currentPosition = seconds;
      });
    } else if (_nativeController != null) {
      _nativeController!.seekTo(Duration(seconds: seconds.round()));
    }
  }

  void _setPlaybackSpeed(double speed) {
    if (_isWebMode) {
      webSetSpeed(_webPlayerId, speed);
    } else if (_nativeController != null) {
      _nativeController!.setPlaybackSpeed(speed);
    }
  }

  void _togglePlayPause() {
    if (_isWebMode) {
      final state = webTogglePlay(_webPlayerId);
      setState(() => _isPlaying = state);
    } else if (_nativeController != null) {
      if (_nativeController!.value.isPlaying) {
        _nativeController!.pause();
        setState(() => _isPlaying = false);
      } else {
        _nativeController!.play();
        setState(() => _isPlaying = true);
      }
    }
    _resetControlsTimer();
  }

  void _cycleSpeed() {
    const speeds = [1.0, 1.25, 1.5, 2.0];
    final nextIdx = (speeds.indexOf(_currentSpeed) + 1) % speeds.length;
    final nextSpeed = speeds[nextIdx];
    setState(() {
      _currentSpeed = nextSpeed;
    });
    _setPlaybackSpeed(nextSpeed);
    _showHudToast('Tốc độ: ${nextSpeed}x');
  }

  void _toggleAspectRatio() {
    setState(() {
      _customScale = 1.0;
      _customOffset = Offset.zero;
      switch (_aspectRatioMode) {
        case AspectRatioMode.fit169:
          _aspectRatioMode = AspectRatioMode.fillScreen;
          break;
        case AspectRatioMode.fillScreen:
          _aspectRatioMode = AspectRatioMode.zoomCinematic;
          break;
        case AspectRatioMode.zoomCinematic:
          _aspectRatioMode = AspectRatioMode.fit169;
          break;
      }
    });
    if (_isWebMode) {
      final fitStr = _aspectRatioMode == AspectRatioMode.fillScreen
          ? 'fill'
          : (_aspectRatioMode == AspectRatioMode.zoomCinematic ? 'cover' : 'contain');
      webSetVideoFit(_webPlayerId, fitStr);
    }
    String toast = '';
    switch (_aspectRatioMode) {
      case AspectRatioMode.fit169:
        toast = 'Tỷ lệ: 16:9 Chuẩn';
        break;
      case AspectRatioMode.fillScreen:
        toast = 'Tỷ lệ: Tràn viền (Fill)';
        break;
      case AspectRatioMode.zoomCinematic:
        toast = 'Tỷ lệ: Phóng to (Zoom)';
        break;
    }
    _showHudToast(toast);
  }

  void _cycleQuality() {
    const qualities = ['1080p FHD', '720p HD', '480p SD', 'Tự động'];
    final nextIdx = (qualities.indexOf(_selectedQuality) + 1) % qualities.length;
    setState(() {
      _selectedQuality = qualities[nextIdx];
    });
    if (_isWebMode) {
      int targetHeight = -1;
      if (_selectedQuality.startsWith('1080')) {
        targetHeight = 1080;
      } else if (_selectedQuality.startsWith('720')) {
        targetHeight = 720;
      } else if (_selectedQuality.startsWith('480')) {
        targetHeight = 480;
      }
      webSetQuality(_webPlayerId, targetHeight);
    }
    _showHudToast('Chất lượng: $_selectedQuality');
  }

  void _toggleEpisodeDrawer() {
    if (!_showEpisodeDrawer) {
      const chunkSize = 20;
      final curIdx = _currentEpisodeList.indexWhere((e) => e.slug == _currentEpisode.slug);
      if (curIdx >= 0) {
        _drawerChunkIndex = curIdx ~/ chunkSize;
      }
    }
    setState(() {
      _showEpisodeDrawer = !_showEpisodeDrawer;
    });
  }

  void _skipIntro() {
    if (_currentPosition < 90) {
      _seekTo(90);
      _showHudToast('Đã bỏ qua mở đầu (01:30)');
    } else {
      _seekTo(_currentPosition + 85);
      _showHudToast('Đã bỏ qua (+85s)');
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _switchEpisode(EpisodeItem nextEp) {
    _saveProgress();
    setState(() {
      _currentEpisode = nextEp;
      _webPlayerId = 'movix_player_${nextEp.slug}_${DateTime.now().millisecondsSinceEpoch % 100000}';
      _currentPosition = 0;
      _totalDuration = 0;
    });
    _startPlaying();
    _showHudToast('Đang phát: ${nextEp.name}');
  }

  void _playNextEpisode() {
    final curIdx = _currentEpisodeList.indexWhere((e) => e.slug == _currentEpisode.slug);
    if (curIdx != -1 && curIdx + 1 < _currentEpisodeList.length) {
      _switchEpisode(_currentEpisodeList[curIdx + 1]);
    }
  }

  void _playPrevEpisode() {
    final curIdx = _currentEpisodeList.indexWhere((e) => e.slug == _currentEpisode.slug);
    if (curIdx > 0) {
      _switchEpisode(_currentEpisodeList[curIdx - 1]);
    }
  }

  // Multi-source Streaming: Đo độ trễ ping thực tế đến các máy chủ phát (ms)
  Future<void> _measureAllServerLatencies() async {
    if (widget.movie.episodes.isEmpty) return;

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    for (int i = 0; i < widget.movie.episodes.length; i++) {
      final server = widget.movie.episodes[i];
      if (server.serverData.isEmpty) continue;

      if (mounted) {
        setState(() => _pingingServers.add(i));
      }

      final testUrl = server.serverData.first.linkM3u8.isNotEmpty
          ? server.serverData.first.linkM3u8
          : server.serverData.first.linkEmbed;

      if (testUrl.isEmpty) {
        if (mounted) {
          setState(() {
            _pingingServers.remove(i);
            _serverLatencies[i] = -1;
          });
        }
        continue;
      }

      () async {
        final stopwatch = Stopwatch()..start();
        try {
          final uri = Uri.tryParse(testUrl);
          if (uri != null && uri.host.isNotEmpty && !kIsWeb) {
            final port = uri.port > 0 ? uri.port : (uri.scheme == 'http' ? 80 : 443);
            final socketMs = await pingHostSocket(uri.host, port, const Duration(seconds: 2));
            if (socketMs != null && socketMs > 0) {
              if (mounted) {
                setState(() {
                  _pingingServers.remove(i);
                  _serverLatencies[i] = socketMs;
                });
              }
              return;
            }
          }

          // Fallback hoặc trên web
          await dio.head(testUrl);
          stopwatch.stop();
          final ms = stopwatch.elapsedMilliseconds;
          if (mounted) {
            setState(() {
              _pingingServers.remove(i);
              _serverLatencies[i] = ms;
            });
          }
        } catch (_) {
          try {
            stopwatch.reset();
            stopwatch.start();
            await dio.get(
              testUrl,
              options: Options(headers: {'Range': 'bytes=0-100'}),
            );
            stopwatch.stop();
            final ms = stopwatch.elapsedMilliseconds;
            if (mounted) {
              setState(() {
                _pingingServers.remove(i);
                _serverLatencies[i] = ms;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _pingingServers.remove(i);
                _serverLatencies[i] = -1;
              });
            }
          }
        }
      }();
    }
  }

  // Chuyển đổi máy chủ phát ngay lập tức (giữ nguyên vị trí đang xem giây thứ mấy)
  void _switchServer(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.movie.episodes.length) return;
    if (newIndex == _selectedServerIndex) return;

    final targetServer = widget.movie.episodes[newIndex];
    if (targetServer.serverData.isEmpty) {
      _showHudToast('Máy chủ này hiện chưa có tập phim');
      return;
    }

    _saveProgress();

    // Tìm tập phim tương ứng trên server mới
    EpisodeItem? matchedEp;
    final bySlug = targetServer.serverData.where((e) => e.slug == _currentEpisode.slug).toList();
    if (bySlug.isNotEmpty) {
      matchedEp = bySlug.first;
    } else {
      final curCleanName = _currentEpisode.name.replaceAll(RegExp(r'[^0-9]'), '');
      if (curCleanName.isNotEmpty) {
        final byNum = targetServer.serverData.where((e) {
          final sClean = e.name.replaceAll(RegExp(r'[^0-9]'), '');
          return sClean == curCleanName;
        }).toList();
        if (byNum.isNotEmpty) matchedEp = byNum.first;
      }
    }

    if (matchedEp == null) {
      final curIdx = _currentEpisodeList.indexWhere((e) => e.slug == _currentEpisode.slug);
      if (curIdx >= 0 && curIdx < targetServer.serverData.length) {
        matchedEp = targetServer.serverData[curIdx];
      } else {
        matchedEp = targetServer.serverData.first;
      }
    }

    final resumePosition = _currentPosition;

    setState(() {
      _selectedServerIndex = newIndex;
      _currentEpisodeList = targetServer.serverData;
      _currentEpisode = matchedEp!;
      _webPlayerId = 'movix_player_${matchedEp.slug}_${DateTime.now().millisecondsSinceEpoch % 100000}';
    });

    if (_isWebMode) {
      webPlay(_webPlayerId);
      if (resumePosition > 0) {
        Future.delayed(const Duration(milliseconds: 600), () {
          webSeekTo(_webPlayerId, resumePosition);
        });
      }
    } else {
      _initNativePlayer(_currentEpisode.linkM3u8);
      if (resumePosition > 0 && _nativeController != null) {
        _nativeController!.seekTo(Duration(seconds: resumePosition.round()));
      }
    }

    final ping = _serverLatencies[newIndex];
    final pingStr = (ping != null && ping > 0) ? ' ($ping ms)' : '';
    _showHudToast('Đã đổi sang: ${targetServer.serverName}$pingStr');
  }

  Color _getServerLatencyColor(int? ms) {
    if (ms == null || ms < 0) return Colors.white54;
    if (ms < 150) return const Color(0xFF22C55E); // Green: Cực nhanh (< 150ms)
    if (ms < 350) return const Color(0xFF22C55E); // Green: Rất tốt (< 350ms)
    if (ms < 600) return const Color(0xFFEAB308); // Yellow: Ổn định (< 600ms)
    return const Color(0xFFEF4444); // Red: Chậm (> 600ms)
  }

  String _getServerLatencyText(int? ms, bool isPinging) {
    if (isPinging) return '...';
    if (ms == null) return '-- ms';
    if (ms < 0) return 'Lỗi';
    return '${ms}ms';
  }

  // Multi-source Streaming: Popover menu chọn máy chủ phát gọn gàng & hiện đại (chuẩn YouTube/Netflix)
  void _showServerSelectionPopover(BuildContext anchorContext) {
    final popoverHeight = (widget.movie.episodes.length * 56.0 + 58.0).clamp(150.0, 310.0);

    showPopover(
      context: anchorContext,
      direction: PopoverDirection.bottom,
      width: 295,
      height: popoverHeight,
      style: PopoverStyle(
        backgroundColor: const Color(0xF8151722),
        radius: 14,
        arrowHeight: 6,
        arrowWidth: 12,
        barrierColor: Colors.black.withValues(alpha: 0.15),
        shadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      bodyBuilder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setPopState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.dns_rounded, color: AppColors.primary, size: 15),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Nguồn phát & Máy chủ',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 16),
                        tooltip: 'Đo lại độ trễ',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        onPressed: () {
                          _measureAllServerLatencies();
                          setPopState(() {});
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 12),
                  // Servers List
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.movie.episodes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, idx) {
                        final server = widget.movie.episodes[idx];
                        final isSelected = _selectedServerIndex == idx;
                        final isPinging = _pingingServers.contains(idx);
                        final ms = _serverLatencies[idx];
                        final latencyColor = _getServerLatencyColor(ms);

                        String pingText = '';
                        if (isPinging) {
                          pingText = 'Đang đo...';
                        } else if (ms != null && ms >= 0) {
                          pingText = '$ms ms';
                        } else {
                          pingText = 'Kém';
                        }

                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _switchServer(idx);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryMuted
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                  color: isSelected ? AppColors.primary : Colors.white38,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              server.serverName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isSelected ? AppColors.primary : Colors.white,
                                                fontSize: 12.5,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (server.serverName.contains('VSMov'))
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFF3B82F6), width: 0.6),
                                              ),
                                              child: const Text(
                                                'VSMov',
                                                style: TextStyle(color: Color(0xFF60A5FA), fontSize: 8.5, fontWeight: FontWeight.bold),
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryMuted,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.primary, width: 0.6),
                                              ),
                                              child: const Text(
                                                'KKPhim',
                                                style: TextStyle(color: AppColors.primary, fontSize: 8.5, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if (isPinging)
                                            const SizedBox(
                                              width: 7,
                                              height: 7,
                                              child: CircularProgressIndicator(strokeWidth: 1.2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)),
                                            )
                                          else
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(color: latencyColor, shape: BoxShape.circle),
                                            ),
                                          const SizedBox(width: 4),
                                          Text(
                                            pingText,
                                            style: TextStyle(color: latencyColor, fontSize: 10.5, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ĐANG PHÁT',
                                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(double seconds) {
    final s = seconds.toInt();
    final mins = s ~/ 60;
    final remSecs = s % 60;
    final hours = mins ~/ 60;
    final remMins = mins % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${remMins.toString().padLeft(2, '0')}:${remSecs.toString().padLeft(2, '0')}';
    }
    return '${remMins.toString().padLeft(2, '0')}:${remSecs.toString().padLeft(2, '0')}';
  }

  // Cài đặt trình phát dạng Popover gọn gàng & hiện đại (chuẩn YouTube/Netflix)
  void _showSettingsPopover(BuildContext anchorContext) {
    showPopover(
      context: anchorContext,
      direction: PopoverDirection.bottom,
      width: 310,
      height: 425,
      style: PopoverStyle(
        backgroundColor: const Color(0xF8151722),
        radius: 14,
        arrowHeight: 6,
        arrowWidth: 12,
        barrierColor: Colors.black.withValues(alpha: 0.15),
        shadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      bodyBuilder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setPopState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 15),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Cài đặt trình phát',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 12),

                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Nguồn phát (nếu có nhiều server)
                          if (widget.movie.episodes.length > 1) ...[
                            InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                _showServerSelectionPopover(anchorContext);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white12, width: 0.8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.dns_rounded, color: AppColors.primary, size: 15),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Nguồn phát & Máy chủ',
                                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            '${widget.movie.episodes[_selectedServerIndex].serverName} • ${_getServerLatencyText(_serverLatencies[_selectedServerIndex], _pingingServers.contains(_selectedServerIndex))}',
                                            style: TextStyle(color: _getServerLatencyColor(_serverLatencies[_selectedServerIndex]), fontSize: 10.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // 2. Độ phân giải (Quality)
                          const Text('Chất lượng video', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 5),
                          Row(
                            children: ['1080p FHD', '720p HD', '480p SD', 'Tự động'].map((q) {
                              final isSel = _selectedQuality == q;
                              final shortLabel = q == 'Tự động' ? 'Auto' : q.split(' ').first;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _selectedQuality = q);
                                      setPopState(() {});
                                      if (_isWebMode) {
                                        int targetHeight = -1;
                                        if (q.startsWith('1080')) targetHeight = 1080;
                                        if (q.startsWith('720')) targetHeight = 720;
                                        if (q.startsWith('480')) targetHeight = 480;
                                        webSetQuality(_webPlayerId, targetHeight);
                                      }
                                      _showHudToast('Chất lượng: $q');
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSel ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        shortLabel,
                                        style: TextStyle(
                                          color: isSel ? Colors.white : Colors.white70,
                                          fontSize: 10.5,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),

                          // Tỉ lệ hiển thị (Aspect Ratio)
                          const Text('Tỷ lệ hiển thị', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              (mode: AspectRatioMode.fit169, label: '16:9 Gốc'),
                              (mode: AspectRatioMode.fillScreen, label: 'Tràn viền'),
                              (mode: AspectRatioMode.zoomCinematic, label: 'Zoom'),
                            ].map((item) {
                              final isSel = _aspectRatioMode == item.mode;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _aspectRatioMode = item.mode);
                                      setPopState(() {});
                                      if (_isWebMode) {
                                        final fitStr = item.mode == AspectRatioMode.fillScreen
                                            ? 'fill'
                                            : (item.mode == AspectRatioMode.zoomCinematic ? 'cover' : 'contain');
                                        webSetVideoFit(_webPlayerId, fitStr);
                                      }
                                      _showHudToast('Tỷ lệ: ${item.label}');
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSel ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          color: isSel ? Colors.white : Colors.white70,
                                          fontSize: 10.5,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),

                          // 3. Tốc độ phát (Playback Speed)
                          Text('Tốc độ phát: ${_currentSpeed}x', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 5),
                          Row(
                            children: [0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                              final isSel = _currentSpeed == s;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _currentSpeed = s);
                                      setPopState(() {});
                                      _setPlaybackSpeed(s);
                                      _showHudToast('Tốc độ: ${s}x');
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSel ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${s}x',
                                        style: TextStyle(
                                          color: isSel ? Colors.white : Colors.white70,
                                          fontSize: 10.5,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),

                          // 4. Âm thanh & Phụ đề
                          const Text('Âm thanh & Phụ đề', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 5),
                          Row(
                            children: ['Tiếng gốc (Vietsub)', 'Thuyết minh', 'Lồng tiếng'].map((t) {
                              final isSel = _selectedAudioTrack == t;
                              final shortLabel = t.contains('Vietsub') ? 'Vietsub' : (t.contains('Thuyết') ? 'Thuyết minh' : 'Lồng tiếng');
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _selectedAudioTrack = t);
                                      setPopState(() {});
                                      _showHudToast('Âm thanh: $t');
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSel ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        shortLabel,
                                        style: TextStyle(
                                          color: isSel ? Colors.white : Colors.white70,
                                          fontSize: 10,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),

                          // 5. Âm lượng (Volume Slider)
                          Row(
                            children: [
                              IconButton(
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                icon: Icon(
                                  _isMuted || _volume == 0
                                      ? Icons.volume_off_rounded
                                      : (_volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  _toggleMute();
                                  setPopState(() {});
                                },
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2.5,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                                    activeTrackColor: AppColors.primary,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: AppColors.primary,
                                  ),
                                  child: Slider(
                                    value: _isMuted ? 0.0 : _volume,
                                    min: 0.0,
                                    max: 1.0,
                                    onChanged: (val) {
                                      _setVolume(val);
                                      setPopState(() {});
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isMuted ? 'Mute' : '${(_volume * 100).round()}%',
                                style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 12),

                          // 5. Switches (Auto next & Skip intro)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tự động chuyển tập', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                              Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  value: _autoPlayNext,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    setState(() => _autoPlayNext = val);
                                    setPopState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Bỏ qua mở đầu (Skip Intro)', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                              Transform.scale(
                                scale: 0.75,
                                child: Switch(
                                  value: _enableSkipIntro,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    setState(() => _enableSkipIntro = val);
                                    setPopState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleExitPlayer() async {
    _saveProgress();
    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _saveProgress();
    _progressSaveTimer?.cancel();
    _tickerTimer?.cancel();
    _controlsTimer?.cancel();
    _hudToastTimer?.cancel();
    _leftRippleTimer?.cancel();
    _rightRippleTimer?.cancel();
    _nativeController?.dispose();
    _focusNode.dispose();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curIdx = _currentEpisodeList.indexWhere((e) => e.slug == _currentEpisode.slug);
    final hasNext = curIdx != -1 && curIdx + 1 < _currentEpisodeList.length;
    final nextEp = hasNext ? _currentEpisodeList[curIdx + 1] : null;

    final showNextEpPrompt = _totalDuration > 60 && (_totalDuration - _currentPosition) <= 90 && hasNext && _autoPlayNext;

    final videoPlayerWidget = KeyedSubtree(
      key: _videoPlayerKey,
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Video Element (Native or Web HLS) with 2-finger pinch & drag-to-reposition
            Positioned.fill(
              child: ClipRect(
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(_customOffset.dx, _customOffset.dy)
                    ..scale(_customScale),
                  alignment: Alignment.center,
                  child: _isWebMode
                      ? buildHlsVideoView(
                          videoElementId: _webPlayerId,
                          m3u8Url: _currentEpisode.linkM3u8,
                          startPosition: _currentPosition > 0 ? _currentPosition : widget.initialPositionSeconds.toDouble(),
                          initialFit: _aspectRatioMode == AspectRatioMode.fillScreen
                              ? 'fill'
                              : (_aspectRatioMode == AspectRatioMode.zoomCinematic ? 'cover' : 'contain'),
                        )
                      : (_nativeController != null && _nativeController!.value.isInitialized
                          ? Center(
                              child: FittedBox(
                                fit: _aspectRatioMode == AspectRatioMode.fillScreen
                                    ? BoxFit.fill
                                    : (_aspectRatioMode == AspectRatioMode.zoomCinematic ? BoxFit.cover : BoxFit.contain),
                                child: SizedBox(
                                  width: _nativeController!.value.size.width > 0
                                      ? _nativeController!.value.size.width
                                      : 16,
                                  height: _nativeController!.value.size.height > 0
                                      ? _nativeController!.value.size.height
                                      : 9,
                                  child: VideoPlayer(_nativeController!),
                                ),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator(color: AppColors.primary))),
                ),
              ),
            ),

            // 2. YouTube Touch & 2-Finger Pinch Gesture Layer
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onPinchScaleStart,
                onScaleUpdate: _onPinchScaleUpdate,
                onScaleEnd: _onPinchScaleEnd,
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                  if (_showControls) {
                    _resetControlsTimer();
                  } else {
                    _controlsTimer?.cancel();
                  }
                },
                onLongPressStart: (_) => _onLongPressStart(),
                onLongPressEnd: (_) => _onLongPressEnd(),
                onLongPressUp: () => _onLongPressEnd(),
                child: Row(
                  children: [
                    // Double tap left: Rewind 10s
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: _onDoubleTapLeft,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    // Center area: double tap resets custom zoom or cycles fit
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () {
                          if (_customScale > 1.05) {
                            _resetPinchZoom();
                          } else {
                            _toggleAspectRatio();
                          }
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    // Double tap right: Fast forward 10s
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: _onDoubleTapRight,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            ),

              // 3. YouTube Ripple Left
              if (_showLeftSeekRipple)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(100)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 36),
                          SizedBox(height: 4),
                          Text('10 giây', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. YouTube Ripple Right
              if (_showRightSeekRipple)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(100)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fast_forward_rounded, color: Colors.white, size: 36),
                          SizedBox(height: 4),
                          Text('10 giây', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),

              // 5. YouTube 2X Speed Indicator
              if (_isLongPressing2X)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fast_forward_rounded, color: AppColors.primary, size: 18),
                          SizedBox(width: 6),
                          Text('2X Tốc độ', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),

              // 6. Floating HUD Toast Pill (Replaces giant white bottom SnackBar)
              if (_hudToastMessage != null)
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        _hudToastMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

              // 7. Netflix-Style: Next Episode Floating Prompt
              if (showNextEpPrompt && !_isLocked && nextEp != null)
                Positioned(
                  bottom: _showControls ? 64 : 16,
                  right: 14,
                  child: ElevatedButton.icon(
                    onPressed: _playNextEpisode,
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                    label: Text('Tập tiếp: ${nextEp.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                ),

              // 8. Mobile Controls Overlay (Clean Stack with Zero Collision)
              if (_showControls && !_isLongPressing2X)
                _buildMobileControlsOverlay(),
            ],
          ),
        ),
    );

    // Single Unified Scaffold with PopScope & Keyboard Listener:
    // N: Next episode, P: Prev episode, Space: Play/Pause, ArrowLeft/Right: Seek 10s, M: Mute
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleExitPlayer();
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.keyN) {
              _playNextEpisode();
            } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
              _playPrevEpisode();
            } else if (event.logicalKey == LogicalKeyboardKey.space) {
              _togglePlayPause();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _seekRelative(10);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _seekRelative(-10);
            } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
              _toggleFullScreen();
            } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
              _toggleMute();
            }
          }
        },
        child: Scaffold(
          key: const ValueKey('unified_player_scaffold_cinema'),
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 100% Immersive Full-screen Video Player (Chuẩn rạp phim Netflix)
              Positioned.fill(child: videoPlayerWidget),

              // Slide-in Episode Drawer on demand (for series)
              if (_showEpisodeDrawer && _currentEpisodeList.length > 1)
                _buildEpisodeDrawer(),
            ],
          ),
        ),
      ),
    );
  }

  // Slide-in Episode Drawer on demand for TV / Tablet Landscape
  Widget _buildEpisodeDrawer() {
    const chunkSize = 20;
    final totalChunks = (_currentEpisodeList.length / chunkSize).ceil();
    final currentChunk = _drawerChunkIndex.clamp(0, totalChunks > 0 ? totalChunks - 1 : 0);
    final startIndex = currentChunk * chunkSize;
    final endIndex = (startIndex + chunkSize).clamp(0, _currentEpisodeList.length);
    final displayedEpisodes = _currentEpisodeList.sublist(startIndex, endIndex);

    final curEpIdx = displayedEpisodes.indexWhere((e) => e.slug == _currentEpisode.slug);
    final initialOffset = (curEpIdx > 3) ? (curEpIdx - 2) * 52.0 : 0.0;

    return Stack(
      children: [
        // Barrier
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _showEpisodeDrawer = false),
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),

        // Slide-in Panel from right
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: 360,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xF20F1014),
              border: const Border(
                left: BorderSide(color: Color(0x33FFFFFF), width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Danh sách tập (${_currentEpisodeList.length} tập)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                          onPressed: () => setState(() => _showEpisodeDrawer = false),
                        ),
                      ],
                    ),
                  ),

                  // Range tabs
                  if (totalChunks > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: List.generate(totalChunks, (c) {
                            final isChunkSelected = c == currentChunk;
                            final cStart = c * chunkSize + 1;
                            final cEnd = ((c + 1) * chunkSize).clamp(1, _currentEpisodeList.length);
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () => setState(() => _drawerChunkIndex = c),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isChunkSelected ? Colors.white : const Color(0x2EFFFFFF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Tập $cStart - $cEnd',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isChunkSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isChunkSelected ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                  const Divider(color: Color(0x1FFFFFFF), height: 1),

                  // Episodes list
                  Expanded(
                    child: ListView.separated(
                      controller: ScrollController(initialScrollOffset: initialOffset),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: displayedEpisodes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final ep = displayedEpisodes[idx];
                        final isPlayingThis = ep.slug == _currentEpisode.slug;
                        final cleanName = ep.name.trim();
                        final epTitle = cleanName.toLowerCase().startsWith('tập') ? cleanName : 'Tập $cleanName';

                        return InkWell(
                          onTap: () {
                            _switchEpisode(ep);
                            setState(() => _showEpisodeDrawer = false);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isPlayingThis
                                  ? AppColors.primaryMuted
                                  : AppColors.surfaceLight.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isPlayingThis ? AppColors.primary : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPlayingThis ? Icons.play_arrow_rounded : Icons.play_circle_outline_rounded,
                                  color: isPlayingThis ? AppColors.primary : AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    epTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isPlayingThis ? AppColors.primary : AppColors.textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: isPlayingThis ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isPlayingThis)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ĐANG PHÁT',
                                      style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile Controls Overlay: Clean Stack with Zero Collision & Netflix Vignettes
  Widget _buildMobileControlsOverlay() {
    final curIdx = _currentEpisodeList.indexWhere((e) => e.slug == _currentEpisode.slug);
    final hasNext = curIdx != -1 && curIdx + 1 < _currentEpisodeList.length;
    final nextEp = hasNext ? _currentEpisodeList[curIdx + 1] : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _showControls = false;
        });
        _controlsTimer?.cancel();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Top Vignette Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC000000),
                      Color(0x80000000),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Bottom Vignette Gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 140,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xEE000000),
                      Color(0x99000000),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Top Bar: Header, Player Source & Actions
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Glass Back Button
                    InkWell(
                      onTap: _handleExitPlayer,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.movie.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                          if (_currentEpisodeList.length > 1 || _currentEpisode.name.isNotEmpty)
                            Text(
                              _currentEpisode.name.toLowerCase().startsWith('tập')
                                  ? _currentEpisode.name
                                  : 'Tập ${_currentEpisode.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Server Source Switcher Pill with Real Latency Ping
                    if (widget.movie.episodes.length > 1) ...[
                      Builder(
                        builder: (pillCtx) {
                          return InkWell(
                            onTap: () => _showServerSelectionPopover(pillCtx),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getServerLatencyColor(_serverLatencies[_selectedServerIndex]),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _getServerLatencyColor(_serverLatencies[_selectedServerIndex]),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _getServerLatencyText(_serverLatencies[_selectedServerIndex], _pingingServers.contains(_selectedServerIndex)),
                                    style: TextStyle(
                                      color: _getServerLatencyColor(_serverLatencies[_selectedServerIndex]),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 105),
                                    child: Text(
                                      widget.movie.episodes[_selectedServerIndex].serverName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 18),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                    ],

                    // Netflix/YouTube Settings button (Popover)
                    Builder(
                      builder: (settingCtx) {
                        return IconButton(
                          icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                          tooltip: 'Cài đặt phát & Chất lượng',
                          onPressed: () => _showSettingsPopover(settingCtx),
                        );
                      },
                    ),

                    // Lock screen button
                    IconButton(
                      icon: Icon(_isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, color: Colors.white, size: 20),
                      tooltip: _isLocked ? 'Mở khóa' : 'Khóa màn hình',
                      onPressed: () {
                        setState(() => _isLocked = !_isLocked);
                        _showHudToast(_isLocked ? 'Đã khóa màn hình' : 'Đã mở khóa màn hình');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Center: Playback Controls (Replay 10s, Play/Pause, Forward 10s)
          if (!_isLocked)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Rewind 10s
                  InkWell(
                    onTap: _onDoubleTapLeft,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(width: 32),

                  // Center Play/Pause 68px glass circular button
                  InkWell(
                    onTap: _togglePlayPause,
                    borderRadius: BorderRadius.circular(36),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),

                  // Forward 10s
                  InkWell(
                    onTap: _onDoubleTapRight,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                ],
              ),
            )
          else
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Màn hình đang khóa (Chạm biểu tượng khóa để mở)',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Floating Skip Intro Button (Netflix Style: directly above progress bar on the right)
          if (!_isLocked && _currentEpisodeList.length > 1 && _enableSkipIntro && _currentPosition <= 120)
            Positioned(
              bottom: 84,
              right: 20,
              child: InkWell(
                onTap: _skipIntro,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fast_forward_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Bỏ qua mở đầu',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 6. Bottom Bar: Scrubber + Time + Drawer + Quality + Aspect Ratio + Speed (Chuẩn Netflix)
          if (!_isLocked)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Red Scrubber Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: Colors.white24,
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        ),
                        child: Slider(
                          value: _currentPosition.clamp(0.0, _totalDuration > 0 ? _totalDuration : 1.0),
                          min: 0.0,
                          max: _totalDuration > 0 ? _totalDuration : 1.0,
                          onChangeStart: (_) {
                            _isDraggingSlider = true;
                          },
                          onChanged: (val) {
                            setState(() {
                              _currentPosition = val;
                            });
                          },
                          onChangeEnd: (val) {
                            _isDraggingSlider = false;
                            _seekTo(val);
                            _resetControlsTimer();
                          },
                        ),
                      ),

                      // Bottom actions row: Responsive theo chiều rộng màn hình
                      Builder(builder: (context) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isCompact = screenWidth < 650;

                        return Row(
                          children: [
                            Text(
                              '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            ),
                            const Spacer(),

                            // Volume / Mute button (chỉ hiện khi đủ chỗ trên màn ngang)
                            if (!isCompact) ...[
                              IconButton(
                                iconSize: 20,
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                icon: Icon(
                                  _isMuted || _volume == 0
                                      ? Icons.volume_off_rounded
                                      : (_volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                                  color: Colors.white,
                                ),
                                tooltip: 'Chỉnh âm lượng',
                                onPressed: _toggleMute,
                              ),
                              const SizedBox(width: 4),
                            ],

                            // Next Episode Quick Button (Bottom Bar Shortcut)
                            if (hasNext) ...[
                              IconButton(
                                iconSize: 22,
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                                tooltip: 'Tập tiếp: ${nextEp!.name} (Phím N)',
                                onPressed: _playNextEpisode,
                              ),
                              const SizedBox(width: 4),
                            ],

                            // Series Episodes Drawer Toggle Button (Only for multi-episode series)
                            if (_currentEpisodeList.length > 1) ...[
                              InkWell(
                                onTap: _toggleEpisodeDrawer,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _showEpisodeDrawer
                                        ? AppColors.primary
                                        : Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.video_library_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tập (${_currentEpisodeList.length})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],

                            // Trên màn hình rộng: hiển thị các nút tắt tiện lợi (1080p, 16:9, Tốc độ)
                            if (!isCompact) ...[
                              // Quality badge button
                              InkWell(
                                onTap: _cycleQuality,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _selectedQuality == 'Tự động' ? 'Auto' : _selectedQuality.split(' ').first,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Aspect ratio toggle button (Fit vs Fill vs Zoom)
                              InkWell(
                                onTap: _toggleAspectRatio,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _aspectRatioLabel,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Speed badge button
                              InkWell(
                                onTap: _cycleSpeed,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_currentSpeed}x',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
