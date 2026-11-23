import 'dart:io';

Future<int?> pingHostSocket(String host, int port, Duration timeout) async {
  final stopwatch = Stopwatch()..start();
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.destroy();
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds;
  } catch (_) {
    return null;
  }
}
