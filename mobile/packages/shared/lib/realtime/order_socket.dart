import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/models.dart';

/// Conexion WebSocket con reconexion automatica (backoff).
/// Emite eventos de pedidos en tiempo real.
class OrderSocket {
  OrderSocket({required this.wsUrl, required String Function() tokenProvider})
      : _tokenProvider = tokenProvider;

  final String wsUrl;
  final String Function() _tokenProvider;

  final _controller = StreamController<RealtimeEvent>.broadcast();
  WebSocketChannel? _channel;
  Timer? _retryTimer;
  bool _disposed = false;
  int _attempt = 0;

  Stream<RealtimeEvent> get events => _controller.stream;

  Future<void> connect() async {
    if (_disposed || _channel != null) return;
    final token = _tokenProvider();
    if (token.isEmpty) return;
    final uri = Uri.parse('$wsUrl/ws/orders?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        _onMessage,
        onError: (_) => _scheduleRetry(),
        onDone: _scheduleRetry,
        cancelOnError: true,
      );
      _attempt = 0;
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _onMessage(dynamic data) {
    if (data is! String) return;
    try {
      final json =
          RegExp('\\{(?:[^{}]|\\{[^{}]*\\})*\\}').firstMatch(data)?.group(0);
      if (json == null) return;
      final event = RealtimeEvent.fromJson(
        (RegExp('"type"\\s*:\\s*"([^"]+)"').firstMatch(json)) == null
            ? {}
            : {
                'type': RegExp('"type"\\s*:\\s*"([^"]+)"')
                    .firstMatch(json)!
                    .group(1),
                'order_id': RegExp('"order_id"\\s*:\\s*"([^"]+)"')
                        .firstMatch(json)
                        ?.group(1) ??
                    '',
                'status': RegExp('"status"\\s*:\\s*"([^"]+)"')
                        .firstMatch(json)
                        ?.group(1) ??
                    '',
              },
      );
      if (event.orderId.isNotEmpty) {
        _controller.add(event);
      }
    } catch (_) {}
  }

  void _scheduleRetry() {
    _channel = null;
    if (_disposed) return;
    _attempt++;
    final delay = Duration(seconds: _attempt <= 1 ? 1 : 5);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, connect);
  }

  Future<void> disconnect() async {
    _disposed = true;
    _retryTimer?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}
