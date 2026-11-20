import 'package:flutter/material.dart';
import 'web_iframe_player_stub.dart'
    if (dart.library.js_interop) 'web_iframe_player_web.dart' as impl;

Widget getIframePlayer({required String viewId, required String embedUrl}) {
  return impl.buildWebIframePlayer(viewId: viewId, embedUrl: embedUrl);
}
