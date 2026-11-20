import 'package:flutter/material.dart';

Widget buildHlsVideoView({required String videoElementId, required String m3u8Url}) {
  return const SizedBox.shrink();
}

void webPlay(String id) {}
void webPause(String id) {}
bool webTogglePlay(String id) => false;
void webSeekRelative(String id, double seconds) {}
void webSeekTo(String id, double seconds) {}
void webSetSpeed(String id, double rate) {}
void webSetVideoFit(String id, String fit) {}
double webGetCurrentTime(String id) => 0.0;
double webGetDuration(String id) => 0.0;
bool webIsPlaying(String id) => false;
bool webToggleFullscreen() => false;
bool webIsFullscreen() => false;
void webSetVolume(String id, double volume) {}
double webGetVolume(String id) => 1.0;
bool webToggleMute(String id) => false;
