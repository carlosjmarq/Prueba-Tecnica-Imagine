import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/models.dart';

/// Conexion WebSocket con reconexion automatica (backoff) y heartbeat.
/// Envia "ping" periodicamente y reconecta si el "pong" no llega a tiempo.
class OrderSocket {
  OrderSocket({required this.wsUrl, required String Function() tokenProvider})
      : _tokenProvider = tokenProvider;

  final String wsUrl;
  final String Function() _tokenProvider;

  static const _pingInterval = Duration(seconds: 20);
  static const _pongTimeout = Duration(seconds: 10);

  final _controller = StreamController<RealtimeEvent>.broadcast();
  WebSocketChannel? _channel;
  Timer? _retryTimer;
  Timer? _pingTimer;
  Timer? _pongTimer;
  bool _disposed = false;
  int _attempt = 0;
  bool _pongReceived = false;

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
      _startHeartbeat();
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _startHeartbeat() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      _pongReceived = false;
      _channel?.sink.add('ping');
      _pongTimer?.cancel();
      _pongTimer = Timer(_pongTimeout, () {
        if (!_pongReceived) _scheduleRetry();
      });
    });
  }

  void _onMessage(dynamic data) {
    if (data is! String) return;
    if (data == 'pong') {
      _pongReceived = true;
      _pongTimer?.cancel();
      return;
    }
    if (data == 'ping') {
      _channel?.sink.add('pong');
      return;
    }
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
    _pingTimer?.cancel();
    _pongTimer?.cancel();
    _cancelChannel();
    if (_disposed) return;
    _attempt++;
    final delay = Duration(seconds: _attempt <= 1 ? 1 : 5);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, connect);
  }

  void _cancelChannel() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  Future<void> disconnect() async {
    _disposed = true;
    _retryTimer?.cancel();
    _pingTimer?.cancel();
    _pongTimer?.cancel();
    _cancelChannel();
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _pingTimer?.cancel();
    _pongTimer?.cancel();
    _cancelChannel();
    _controller.close();
  }
}
