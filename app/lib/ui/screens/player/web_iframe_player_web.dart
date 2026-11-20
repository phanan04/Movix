// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViews = <String>{};

Widget buildWebIframePlayer({required String viewId, required String embedUrl}) {
  if (!_registeredViews.contains(viewId)) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) {
        final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
        iframe.src = embedUrl;
        iframe.style.border = 'none';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.setAttribute('allowfullscreen', 'true');
        iframe.setAttribute('allow', 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture');
        return iframe;
      },
    );
    _registeredViews.add(viewId);
  }

  return HtmlElementView(viewType: viewId);
}
