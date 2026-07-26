import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Singleton client for the tomoro-store Unix socket daemon.
///
/// Call [StoreClient.instance] to get the shared instance.
/// Subscribe to [events] for daemon messages (progress, installed, etc.).
/// Use [send] to dispatch commands.
class StoreClient {
  StoreClient._();

  static final StoreClient instance = StoreClient._();

  static const _sockPath = '/run/tomoro/store.sock';

  Socket? _socket;
  final StreamController<Map<String, dynamic>> _ctrl =
      StreamController.broadcast();
  StreamSubscription<String>? _sub;
  bool _connecting = false;

  Stream<Map<String, dynamic>> get events => _ctrl.stream;

  Future<void> connect() async {
    if (_socket != null || _connecting) return;
    _connecting = true;
    try {
      _socket = await Socket.connect(
        InternetAddress(_sockPath, type: InternetAddressType.unix),
        0,
      );
      _sub = _socket!
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _onLine,
            onDone: _onDisconnect,
            onError: (_) => _onDisconnect(),
            cancelOnError: false,
          );
    } catch (_) {
      _socket = null;
    } finally {
      _connecting = false;
    }
  }

  void _onLine(String line) {
    if (line.isEmpty) return;
    try {
      final map = jsonDecode(line) as Map<String, dynamic>;
      _ctrl.add(map);
    } catch (_) {}
  }

  void _onDisconnect() {
    _sub?.cancel();
    _socket?.destroy();
    _socket = null;
    // reconnect after a short delay
    Future.delayed(const Duration(seconds: 3), connect);
  }

  Future<void> send(Map<String, dynamic> cmd) async {
    await connect();
    final socket = _socket;
    if (socket == null) return;
    socket.write('${jsonEncode(cmd)}\n');
  }

  void dispose() {
    _sub?.cancel();
    _socket?.destroy();
    _ctrl.close();
  }
}
