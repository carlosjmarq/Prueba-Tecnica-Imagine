import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../core/providers.dart';

/// Notifier de autenticación del repartidor (solo login).
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

  void logout() {
    _ref.read(authSessionProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>(
  (ref) => AuthController(ref),
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authSessionProvider) != null;
});
