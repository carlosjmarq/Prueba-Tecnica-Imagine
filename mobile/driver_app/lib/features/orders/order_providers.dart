import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../core/providers.dart';

/// Pedidos disponibles (PENDING) para aceptar.
/// Depende de la sesión: al cambiar de usuario (login/logout) se re-ejecuta.
final availableOrdersProvider = FutureProvider<List<Order>>((ref) async {
  ref.watch(authSessionProvider);
  final api = ref.watch(apiClientProvider);
  return api.availableOrders();
});

/// Pedidos asignados a mí.
final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  ref.watch(authSessionProvider);
  final api = ref.watch(apiClientProvider);
  return api.myAssignedOrders();
});

/// Escucha eventos realtime y refresca las listas.
final realtimeListenerProvider = Provider<void>((ref) {
  ref.listen(realtimeEventsProvider, (prev, next) {
    next.whenData((event) {
      if (event.isOrderCreated || event.isOrderUpdate) {
        ref.invalidate(availableOrdersProvider);
        ref.invalidate(myOrdersProvider);
      }
    });
  });
  return;
});

/// Notifier para aceptar y actualizar estado.
class OrderActionController extends StateNotifier<AsyncValue<Order?>> {
  OrderActionController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> accept(String orderId) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      await api.acceptOrder(orderId);
      state = const AsyncValue.data(null);
      _ref.invalidate(availableOrdersProvider);
      _ref.invalidate(myOrdersProvider);
      return true;
    } catch (e) {
      state = AsyncValue.error(ApiClient.mapError(e), StackTrace.current);
      return false;
    }
  }

  Future<bool> updateStatus(String orderId, String status) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      await api.updateOrderStatus(orderId, status);
      state = const AsyncValue.data(null);
      _ref.invalidate(availableOrdersProvider);
      _ref.invalidate(myOrdersProvider);
      return true;
    } catch (e) {
      state = AsyncValue.error(ApiClient.mapError(e), StackTrace.current);
      return false;
    }
  }
}

final orderActionControllerProvider =
    StateNotifierProvider<OrderActionController, AsyncValue<Order?>>(
  (ref) => OrderActionController(ref),
);
