import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../core/providers.dart';

/// Notifier que ejecuta login/register y actualiza la sesión.
class AuthController extends StateNotifier<AsyncValue<User?>> {
  AuthController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      final pair = await api.login(email, password);
      _ref.read(authSessionProvider.notifier).state = AuthSession(
          accessToken: pair.accessToken, refreshToken: pair.refreshToken);
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
      _ref.read(authSessionProvider.notifier).state = AuthSession(
          accessToken: pair.accessToken, refreshToken: pair.refreshToken);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(ApiClient.mapError(e), StackTrace.current);
      return false;
    }
  }

  void logout() {
    _ref.read(authSessionProvider.notifier).state = null;
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
