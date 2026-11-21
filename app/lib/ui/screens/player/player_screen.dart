import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../core/cache/user_storage.dart';
import '../../../core/models/movie_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/episode_grid_widget.dart';
import 'web_iframe_player.dart';
import 'web_player_controller.dart';

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

  final bool _isWebMode = kIsWeb;
  bool _useIframeFallback = false;
  bool _isPlaying = true;
  bool _isLocked = false;
  bool _showControls = true;
  bool _isLongPressing2X = false;
  bool _isFullScreen = false;
  double _currentSpeed = 1.0;
  bool _isZoomFit = false;

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

  @override
  void initState() {
    super.initState();
    _currentEpisode = widget.episode;
    _webPlayerId = 'movix_player_${_currentEpisode.slug}_${DateTime.now().millisecondsSinceEpoch % 100000}';
    _startPlaying();

    // Sync position every 300ms
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 300), (_) => _syncPlaybackState());

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
      if (!_useIframeFallback) {
        webPlay(_webPlayerId);
      }
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
      if (mounted) {
        setState(() {
          _useIframeFallback = true;
        });
      }
    }
  }

  void _syncPlaybackState() {
    if (!mounted || _isDraggingSlider) return;

    if (_isWebMode && !_useIframeFallback) {
      final pos = webGetCurrentTime(_webPlayerId);
      final dur = webGetDuration(_webPlayerId);
      final playing = webIsPlaying(_webPlayerId);
      setState(() {
        _currentPosition = pos;
        if (dur > 0) _totalDuration = dur;
        _isPlaying = playing;
      });
    } else if (_nativeController != null && _nativeController!.value.isInitialized) {
      setState(() {
        _currentPosition = _nativeController!.value.position.inSeconds.toDouble();
        _totalDuration = _nativeController!.value.duration.inSeconds.toDouble();
        _isPlaying = _nativeController!.value.isPlaying;
      });
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
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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

  void _seekRelative(double seconds) {
    if (_isWebMode && !_useIframeFallback) {
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
    if (_isWebMode && !_useIframeFallback) {
      webSeekTo(_webPlayerId, seconds);
      setState(() {
        _currentPosition = seconds;
      });
    } else if (_nativeController != null) {
      _nativeController!.seekTo(Duration(seconds: seconds.round()));
    }
  }

  void _setPlaybackSpeed(double speed) {
    if (_isWebMode && !_useIframeFallback) {
      webSetSpeed(_webPlayerId, speed);
    } else if (_nativeController != null) {
      _nativeController!.setPlaybackSpeed(speed);
    }
  }

  void _togglePlayPause() {
    if (_isWebMode && !_useIframeFallback) {
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
      _isZoomFit = !_isZoomFit;
    });
    if (_isWebMode) {
      webSetVideoFit(_webPlayerId, _isZoomFit ? 'cover' : 'contain');
    }
    _showHudToast(_isZoomFit ? 'Tỷ lệ: Cắt tràn viền' : 'Tỷ lệ: 16:9 Chuẩn');
  }

  void _cycleQuality() {
    const qualities = ['1080p FHD', '720p HD', '480p SD', 'Tự động'];
    final nextIdx = (qualities.indexOf(_selectedQuality) + 1) % qualities.length;
    setState(() {
      _selectedQuality = qualities[nextIdx];
    });
    _showHudToast('Chất lượng: $_selectedQuality');
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
    final curIdx = widget.allEpisodes.indexWhere((e) => e.slug == _currentEpisode.slug);
    if (curIdx != -1 && curIdx + 1 < widget.allEpisodes.length) {
      _switchEpisode(widget.allEpisodes[curIdx + 1]);
    }
  }

  void _playPrevEpisode() {
    final curIdx = widget.allEpisodes.indexWhere((e) => e.slug == _currentEpisode.slug);
    if (curIdx > 0) {
      _switchEpisode(widget.allEpisodes[curIdx - 1]);
    }
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

  // Redesigned Settings Sheet: Clean, focused, non-duplicated, fully responsive in landscape & portrait
  void _showAudioSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
            final sheetHeight = isLandscape
                ? MediaQuery.of(context).size.height * 0.95
                : MediaQuery.of(context).size.height * 0.8;

            Widget volumeTile() {
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: IconButton(
                  icon: Icon(
                    _isMuted || _volume == 0
                        ? Icons.volume_off_rounded
                        : (_volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    _toggleMute();
                    setSheetState(() {});
                  },
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Âm lượng phim', style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text(
                      _isMuted ? 'Tắt tiếng' : '${(_volume * 100).round()}%',
                      style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                subtitle: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: _isMuted ? 0.0 : _volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    activeColor: AppColors.primary,
                    inactiveColor: Colors.white24,
                    onChanged: (val) {
                      _setVolume(val);
                      setSheetState(() {});
                    },
                  ),
                ),
              );
            }

            Widget resolutionTile() {
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.hd_rounded, color: AppColors.primary, size: 22),
                title: const Text('Độ phân giải video', style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text(_selectedQuality, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedQuality,
                    dropdownColor: AppColors.surfaceLight,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    items: ['1080p FHD', '720p HD', '480p SD', 'Tự động'].map((q) {
                      return DropdownMenuItem(value: q, child: Text(q));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => _selectedQuality = val);
                        setState(() => _selectedQuality = val);
                        _showHudToast('Độ phân giải: $val');
                      }
                    },
                  ),
                ),
              );
            }

            Widget audioSubtitleTile() {
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.subtitles_rounded, color: AppColors.primary, size: 22),
                title: const Text('Âm thanh & Phụ đề', style: TextStyle(color: Colors.white, fontSize: 13)),
                subtitle: Text(_selectedAudioTrack, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAudioTrack,
                    dropdownColor: AppColors.surfaceLight,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    items: ['Tiếng gốc (Vietsub)', 'Thuyết minh Việt', 'Lồng tiếng'].map((t) {
                      return DropdownMenuItem(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => _selectedAudioTrack = val);
                        setState(() => _selectedAudioTrack = val);
                        _showHudToast('Đã chọn: $val');
                      }
                    },
                  ),
                ),
              );
            }

            Widget autoPlayNextTile() {
              return SwitchListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                secondary: const Icon(Icons.playlist_play_rounded, color: AppColors.primary, size: 22),
                title: const Text('Tự động chuyển tập tiếp', style: TextStyle(color: Colors.white, fontSize: 13)),
                value: _autoPlayNext,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setSheetState(() => _autoPlayNext = val);
                  setState(() => _autoPlayNext = val);
                },
              );
            }

            Widget skipIntroTile() {
              return SwitchListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                secondary: const Icon(Icons.skip_next_rounded, color: AppColors.primary, size: 22),
                title: const Text('Bỏ qua đoạn mở đầu (Intro)', style: TextStyle(color: Colors.white, fontSize: 13)),
                value: _enableSkipIntro,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setSheetState(() => _enableSkipIntro = val);
                  setState(() => _enableSkipIntro = val);
                },
              );
            }

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: sheetHeight,
                maxWidth: isLandscape ? 680 : 500,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Header Row with Title & Close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cài đặt phát & Âm thanh',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Content: 2-Column in landscape, 1-Column in portrait
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: isLandscape
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          volumeTile(),
                                          const Divider(color: AppColors.border, height: 1),
                                          resolutionTile(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          audioSubtitleTile(),
                                          const Divider(color: AppColors.border, height: 1),
                                          autoPlayNextTile(),
                                          skipIntroTile(),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    volumeTile(),
                                    const Divider(color: AppColors.border, height: 1),
                                    resolutionTile(),
                                    const Divider(color: AppColors.border, height: 1),
                                    audioSubtitleTile(),
                                    const Divider(color: AppColors.border, height: 1),
                                    autoPlayNextTile(),
                                    skipIntroTile(),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTabletLandscape = width >= 720;

    final curIdx = widget.allEpisodes.indexWhere((e) => e.slug == _currentEpisode.slug);
    final hasPrev = curIdx > 0;
    final hasNext = curIdx != -1 && curIdx + 1 < widget.allEpisodes.length;
    final nextEp = hasNext ? widget.allEpisodes[curIdx + 1] : null;

    final isSeries = widget.allEpisodes.length > 1;
    final showNextEpPrompt = _totalDuration > 60 && (_totalDuration - _currentPosition) <= 90 && hasNext && _autoPlayNext;

    final videoPlayerWidget = KeyedSubtree(
      key: _videoPlayerKey,
      child: Container(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video Element (Native or Web HLS or Embed Fallback)
              Positioned.fill(
                child: _useIframeFallback
                    ? getIframePlayer(
                        viewId: 'iframe_${_currentEpisode.slug}',
                        embedUrl: _currentEpisode.linkEmbed.isNotEmpty
                            ? _currentEpisode.linkEmbed
                            : _currentEpisode.linkM3u8,
                      )
                    : (_isWebMode
                        ? buildHlsVideoView(
                            videoElementId: _webPlayerId,
                            m3u8Url: _currentEpisode.linkM3u8,
                          )
                        : (_nativeController != null && _nativeController!.value.isInitialized
                            ? FittedBox(
                                fit: _isZoomFit ? BoxFit.cover : BoxFit.contain,
                                child: SizedBox(
                                  width: _nativeController!.value.size.width > 0
                                      ? _nativeController!.value.size.width
                                      : 16,
                                  height: _nativeController!.value.size.height > 0
                                      ? _nativeController!.value.size.height
                                      : 9,
                                  child: VideoPlayer(_nativeController!),
                                ),
                              )
                            : const Center(child: CircularProgressIndicator(color: AppColors.primary)))),
              ),

              // 2. YouTube Touch Gesture Layer: Single tap toggles show/hide controls cleanly
              if (!_useIframeFallback)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
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
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onDoubleTap: _onDoubleTapLeft,
                            child: Container(color: Colors.transparent),
                          ),
                        ),
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
      ),
    );

    final controlsBar = isSeries
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF16181F),
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: TextButton.icon(
                    onPressed: hasPrev ? _playPrevEpisode : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: hasPrev ? Colors.white : AppColors.textMuted,
                    ),
                    icon: const Icon(Icons.skip_previous_rounded, size: 16),
                    label: const Text('Tập trước', style: TextStyle(fontSize: 12), maxLines: 1),
                  ),
                ),
                Flexible(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _useIframeFallback = !_useIframeFallback;
                        if (!_useIframeFallback) {
                          _startPlaying();
                        }
                      });
                      _showHudToast(_useIframeFallback ? 'Đã đổi Embed Dự Phòng' : 'Đã đổi Player Tối Ưu Mobile');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      _useIframeFallback ? Icons.ondemand_video_rounded : Icons.flash_on_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      _useIframeFallback ? 'Dự phòng' : 'HLS Nhanh',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                      maxLines: 1,
                    ),
                  ),
                ),
                Flexible(
                  child: TextButton.icon(
                    onPressed: hasNext ? _playNextEpisode : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: hasNext ? Colors.white : AppColors.textMuted,
                    ),
                    icon: const Icon(Icons.skip_next_rounded, size: 16),
                    label: const Text('Tập tiếp', style: TextStyle(fontSize: 12), maxLines: 1),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    // Single Unified Scaffold: Immersive Fullscreen on Tablet/TV Landscape, and Clean Layout on Portrait
    return Scaffold(
      key: const ValueKey('unified_player_scaffold'),
      backgroundColor: Colors.black,
      body: SafeArea(
        top: !_isFullScreen && !isTabletLandscape,
        bottom: !_isFullScreen && !isTabletLandscape,
        left: false,
        right: false,
        child: isTabletLandscape || _isFullScreen
            ? Stack(
                fit: StackFit.expand,
                children: [
                  // 100% Immersive Full-screen Video Player
                  Center(child: videoPlayerWidget),

                  // Slide-in Episode Drawer on demand (for series)
                  if (_showEpisodeDrawer && widget.allEpisodes.length > 1)
                    _buildEpisodeDrawer(),
                ],
              )
            : Column(
                children: [
                  // Mobile Portrait: Video Player 16:9 on top
                  videoPlayerWidget,
                  controlsBar,

                  // Episodes list & information below
                  Expanded(
                    child: Container(
                      color: AppColors.background,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          if (widget.allEpisodes.length > 1)
                            EpisodeGridWidget(
                              episodes: widget.allEpisodes,
                              currentEpisodeSlug: _currentEpisode.slug,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              onEpisodeSelected: (ep) => _switchEpisode(ep),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Slide-in Episode Drawer on demand for TV / Tablet Landscape
  Widget _buildEpisodeDrawer() {
    const chunkSize = 20;
    final totalChunks = (widget.allEpisodes.length / chunkSize).ceil();
    final currentChunk = _drawerChunkIndex.clamp(0, totalChunks > 0 ? totalChunks - 1 : 0);
    final startIndex = currentChunk * chunkSize;
    final endIndex = (startIndex + chunkSize).clamp(0, widget.allEpisodes.length);
    final displayedEpisodes = widget.allEpisodes.sublist(startIndex, endIndex);

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
                          'Danh sách tập (${widget.allEpisodes.length} tập)',
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
                            final cEnd = ((c + 1) * chunkSize).clamp(1, widget.allEpisodes.length);
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
                                  ? const Color(0xFFE50914).withValues(alpha: 0.2)
                                  : const Color(0xFF1E2028).withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isPlayingThis ? const Color(0xFFE50914) : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPlayingThis ? Icons.play_arrow_rounded : Icons.play_circle_outline_rounded,
                                  color: isPlayingThis ? const Color(0xFFE50914) : Colors.white60,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    epTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isPlayingThis ? const Color(0xFFE50914) : Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: isPlayingThis ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isPlayingThis)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE50914),
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
                      onTap: () => Navigator.pop(context),
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
                          if (widget.allEpisodes.length > 1 || _currentEpisode.name.isNotEmpty)
                            Text(
                              _currentEpisode.name.toLowerCase().startsWith('tập')
                                  ? _currentEpisode.name
                                  : 'Tập ${_currentEpisode.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFE50914),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Quick Switch Player Source (HLS Nhanh vs Dự Phòng)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _useIframeFallback = !_useIframeFallback;
                          if (!_useIframeFallback) {
                            _startPlaying();
                          }
                        });
                        _showHudToast(_useIframeFallback ? 'Đã đổi Embed Dự Phòng' : 'Đã đổi Player HLS Nhanh');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _useIframeFallback
                              ? const Color(0xFFE50914).withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _useIframeFallback ? const Color(0xFFE50914) : Colors.white24,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _useIframeFallback ? Icons.ondemand_video_rounded : Icons.flash_on_rounded,
                              size: 14,
                              color: _useIframeFallback ? const Color(0xFFE50914) : Colors.amberAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _useIframeFallback ? 'Dự phòng' : 'HLS Nhanh',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _useIframeFallback ? const Color(0xFFE50914) : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Netflix Settings / Audio / Resolution button
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                      tooltip: 'Cài đặt phát & Chất lượng',
                      onPressed: _showAudioSettingsSheet,
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

                  // Center Play/Pause 62px glass circular button
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
          if (!_isLocked && widget.allEpisodes.length > 1 && _enableSkipIntro && _currentPosition <= 120)
            Positioned(
              bottom: 56,
              right: 16,
              child: InkWell(
                onTap: _skipIntro,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914),
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

          // 6. Bottom Bar: Scrubber + Time + Drawer + Quality + Aspect Ratio + Speed + Fullscreen
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
                          thumbColor: const Color(0xFFE50914),
                          activeTrackColor: const Color(0xFFE50914),
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

                      // Bottom actions row
                      Row(
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

                          // Volume / Mute button
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

                          // Series Episodes Drawer Toggle Button (Only for multi-episode series)
                          if (widget.allEpisodes.length > 1) ...[
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showEpisodeDrawer = !_showEpisodeDrawer;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _showEpisodeDrawer
                                      ? const Color(0xFFE50914)
                                      : Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.video_library_rounded, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tập (${widget.allEpisodes.length})',
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

                          // Aspect ratio toggle button (Fit vs Zoom)
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
                                _isZoomFit ? 'Zoom' : '16:9',
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

                          // Prominent Fullscreen Button
                          IconButton(
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(
                              _isFullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                              color: Colors.white,
                            ),
                            tooltip: _isFullScreen ? 'Thu nhỏ' : 'Toàn màn hình',
                            onPressed: _toggleFullScreen,
                          ),
                        ],
                      ),
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
