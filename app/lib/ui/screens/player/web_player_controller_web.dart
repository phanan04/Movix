// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('MovixPlayer.createPlayer')
external void _createPlayer(JSString id, JSString src, JSBoolean autoplay, JSNumber startPosition);

@JS('MovixPlayer.setQuality')
external void _setQuality(JSString id, JSNumber height);

@JS('MovixPlayer.play')
external void _play(JSString id);

@JS('MovixPlayer.pause')
external void _pause(JSString id);

@JS('MovixPlayer.togglePlay')
external JSBoolean _togglePlay(JSString id);

@JS('MovixPlayer.seekRelative')
external JSNumber _seekRelative(JSString id, JSNumber seconds);

@JS('MovixPlayer.seekTo')
external void _seekTo(JSString id, JSNumber seconds);

@JS('MovixPlayer.setSpeed')
external void _setSpeed(JSString id, JSNumber rate);

@JS('MovixPlayer.getCurrentTime')
external JSNumber _getCurrentTime(JSString id);

@JS('MovixPlayer.getDuration')
external JSNumber _getDuration(JSString id);

@JS('MovixPlayer.isPlaying')
external JSBoolean _isPlaying(JSString id);

@JS('MovixPlayer.toggleFullscreen')
external JSBoolean _toggleFullscreen();

@JS('MovixPlayer.isFullscreen')
external JSBoolean _isFullscreen();

@JS('MovixPlayer.setVideoFit')
external void _setVideoFit(JSString id, JSString fit);

@JS('MovixPlayer.setVolume')
external void _setVolume(JSString id, JSNumber vol);

@JS('MovixPlayer.getVolume')
external JSNumber _getVolume(JSString id);

@JS('MovixPlayer.toggleMute')
external JSBoolean _toggleMute(JSString id);

final Set<String> _registeredPlayerViews = <String>{};

Widget buildHlsVideoView({
  required String videoElementId,
  required String m3u8Url,
  double startPosition = 0,
}) {
  if (!_registeredPlayerViews.contains(videoElementId)) {
    ui_web.platformViewRegistry.registerViewFactory(
      videoElementId,
      (int id) {
        final video = web.document.createElement('video') as web.HTMLVideoElement;
        video.id = videoElementId;
        video.style.width = '100%';
        video.style.height = '100%';
        video.style.objectFit = 'contain';
        video.style.backgroundColor = 'black';
        video.style.pointerEvents = 'none'; // Flutter receives all gestures on top!
        video.setAttribute('playsinline', 'true');
        video.setAttribute('webkit-playsinline', 'true');

        // Allow DOM to insert before attaching Hls.js
        web.window.setTimeout(
          (() {
            _createPlayer(videoElementId.toJS, m3u8Url.toJS, true.toJS, startPosition.toJS);
          }).toJS,
          50.toJS,
        );

        return video;
      },
    );
    _registeredPlayerViews.add(videoElementId);
  }

  return HtmlElementView(viewType: videoElementId);
}

void webSetQuality(String id, int height) {
  try {
    _setQuality(id.toJS, height.toJS);
  } catch (e) {
    debugPrint('webSetQuality error: $e');
  }
}

void webPlay(String id) {
  try {
    _play(id.toJS);
  } catch (e) {
    debugPrint('webPlay error: $e');
  }
}

void webPause(String id) {
  try {
    _pause(id.toJS);
  } catch (e) {
    debugPrint('webPause error: $e');
  }
}

bool webTogglePlay(String id) {
  try {
    return _togglePlay(id.toJS).toDart;
  } catch (e) {
    debugPrint('webTogglePlay error: $e');
    return false;
  }
}

void webSeekRelative(String id, double seconds) {
  try {
    _seekRelative(id.toJS, seconds.toJS);
  } catch (e) {
    debugPrint('webSeekRelative error: $e');
  }
}

void webSeekTo(String id, double seconds) {
  try {
    _seekTo(id.toJS, seconds.toJS);
  } catch (e) {
    debugPrint('webSeekTo error: $e');
  }
}

void webSetSpeed(String id, double rate) {
  try {
    _setSpeed(id.toJS, rate.toJS);
  } catch (e) {
    debugPrint('webSetSpeed error: $e');
  }
}

void webSetVideoFit(String id, String fit) {
  try {
    _setVideoFit(id.toJS, fit.toJS);
  } catch (e) {
    debugPrint('webSetVideoFit error: $e');
  }
}

double webGetCurrentTime(String id) {
  try {
    return _getCurrentTime(id.toJS).toDartDouble;
  } catch (e) {
    return 0.0;
  }
}

double webGetDuration(String id) {
  try {
    return _getDuration(id.toJS).toDartDouble;
  } catch (e) {
    return 0.0;
  }
}

bool webIsPlaying(String id) {
  try {
    return _isPlaying(id.toJS).toDart;
  } catch (e) {
    return false;
  }
}

bool webToggleFullscreen() {
  try {
    return _toggleFullscreen().toDart;
  } catch (e) {
    debugPrint('webToggleFullscreen error: $e');
    return false;
  }
}

bool webIsFullscreen() {
  try {
    return _isFullscreen().toDart;
  } catch (e) {
    return false;
  }
}

void webSetVolume(String id, double volume) {
  try {
    _setVolume(id.toJS, volume.toJS);
  } catch (e) {
    debugPrint('webSetVolume error: $e');
  }
}

double webGetVolume(String id) {
  try {
    return _getVolume(id.toJS).toDartDouble;
  } catch (e) {
    return 1.0;
  }
}

bool webToggleMute(String id) {
  try {
    return _toggleMute(id.toJS).toDart;
  } catch (e) {
    return false;
  }
}
