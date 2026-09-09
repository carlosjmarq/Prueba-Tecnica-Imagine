import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../core/providers.dart';
import '../orders/order_providers.dart';

/// Notifier que ejecuta login/register y actualiza la sesión.
class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> _storeSession(TokenPair pair) async {
    _ref.read(authSessionProvider.notifier).state = AuthSession(
      accessToken: pair.accessToken,
      refreshToken: pair.refreshToken,
    );
    try {
      final api = _ref.read(apiClientProvider);
      final user = await api.me();
      _ref.read(currentUserProvider.notifier).state = user;
    } catch (_) {
      _ref.read(currentUserProvider.notifier).state = null;
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      final pair = await api.login(email, password);
      await _storeSession(pair);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(ApiClient.mapError(e), StackTrace.current);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String fullName,
    required String password,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      final pair = await api.register(
        email: email,
        fullName: fullName,
        password: password,
        role: role,
      );
      await _storeSession(pair);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(ApiClient.mapError(e), StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    final session = _ref.read(authSessionProvider);
    final refresh = session?.refreshToken;
    if (refresh != null) {
      try {
        await _ref.read(apiClientProvider).logout(refresh);
      } catch (_) {
        // si el backend falla, igual limpiamos la sesión local
      }
    }
    _ref.read(authSessionProvider.notifier).state = null;
    _ref.read(currentUserProvider.notifier).state = null;
    // Invalida datos del usuario anterior para que el siguiente login arranque limpio.
    _ref.invalidate(myOrdersProvider);
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>(
  (ref) => AuthController(ref),
);

/// true si hay sesión activa.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authSessionProvider) != null;
});
