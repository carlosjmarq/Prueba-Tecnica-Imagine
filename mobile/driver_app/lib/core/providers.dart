import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

/// Sesión de auth compartida (access + refresh).
final authSessionProvider = StateProvider<AuthSession?>((ref) => null);

/// Usuario autenticado actual (se puebla tras login via /me).
final currentUserProvider = StateProvider<User?>((ref) => null);

/// Cliente HTTP configurado con el token actual y refresh automático.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ApiConfig.current,
    tokenProvider: () =>
        ref.read(authSessionProvider) ?? AuthSession(accessToken: ''),
    refreshCall: (refreshToken) async {
      final res = await DioAuth.refresh(refreshToken);
      return res;
    },
    // Al refrescar, reemplaza la sesión (nuevo objeto) para que providers que
    // la observan (p. ej. el WebSocket) se reconstruyan con el token nuevo.
    onSessionRefreshed: (session) {
      ref.read(authSessionProvider.notifier).state = AuthSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    },
  );
});

/// Lógica de refresh reutilizable (evita ciclo con el propio cliente).
abstract final class DioAuth {
  static Future<TokenPair> refresh(String refreshToken) async {
    final dio = DioClientFactory.create();
    final res = await dio.post<Map<String, dynamic>>(
      '${ApiConfig.current.baseUrl}/api/v1/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return TokenPair.fromJson(res.data!);
  }
}

/// Socket de eventos en tiempo real, reconectado al iniciar sesión.
final orderSocketProvider = Provider<OrderSocket?>((ref) {
  final token = ref.watch(authSessionProvider)?.accessToken ?? '';
  if (token.isEmpty) return null;
  final socket = OrderSocket(
    wsUrl: ApiConfig.current.wsUrl,
    tokenProvider: () => ref.read(authSessionProvider)?.accessToken ?? '',
  );
  socket.connect();
  ref.onDispose(socket.dispose);
  return socket;
});

/// Eventos de realtime.
final realtimeEventsProvider = StreamProvider<RealtimeEvent>((ref) {
  final socket = ref.watch(orderSocketProvider);
  return socket?.events ?? const Stream.empty();
});
