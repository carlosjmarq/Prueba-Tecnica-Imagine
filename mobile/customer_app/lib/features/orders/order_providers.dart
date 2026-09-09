import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../core/providers.dart';

/// Lista de mis pedidos (customer).
/// Depende de la sesión: al cambiar de usuario (login/logout) se re-ejecuta.
final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  ref.watch(authSessionProvider);
  final api = ref.watch(apiClientProvider);
  return api.myOrders();
});

/// Detalle de un pedido, actualizable en tiempo real.
final orderDetailProvider =
    FutureProvider.family<Order, String>((ref, orderId) async {
  ref.watch(authSessionProvider);
  final api = ref.watch(apiClientProvider);
  return api.orderDetail(orderId);
});

/// Escucha eventos realtime y refresca la lista/detalle afectados.
final realtimeListenerProvider = Provider<void>((ref) {
  ref.listen(realtimeEventsProvider, (prev, next) {
    next.whenData((event) {
      if (event.isOrderUpdate || event.isOrderCreated) {
        ref.invalidate(myOrdersProvider);
        if (ref.exists(orderDetailProvider(event.orderId))) {
          ref.invalidate(orderDetailProvider(event.orderId));
        }
      }
    });
  });
  return;
});

/// Notifier para crear pedidos.
class CreateOrderController extends StateNotifier<AsyncValue<Order?>> {
  CreateOrderController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> create({
    required String pickupAddress,
    required String deliveryAddress,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiClientProvider);
      final order = await api.createOrder(
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        notes: notes,
        items: items,
      );
      state = AsyncValue.data(order);
      _ref.invalidate(myOrdersProvider);
      return true;
    } catch (e) {
      state = AsyncValue.error(ApiClient.mapError(e), StackTrace.current);
      return false;
    }
  }
}

final createOrderControllerProvider =
    StateNotifierProvider<CreateOrderController, AsyncValue<Order?>>(
  (ref) => CreateOrderController(ref),
);
