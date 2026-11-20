import 'package:flutter/material.dart';

Widget buildWebIframePlayer({required String viewId, required String embedUrl}) {
  return const Center(
    child: Text(
      'Web player is not supported on this platform',
      style: TextStyle(color: Colors.white),
    ),
  );
}
