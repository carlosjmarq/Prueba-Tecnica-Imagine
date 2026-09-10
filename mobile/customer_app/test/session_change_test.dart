import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import 'package:customer_app/core/providers.dart';
import 'package:customer_app/features/orders/orders_list_screen.dart';

/// Cliente falso que devuelve pedidos distintos segun el token de la sesion,
/// para verificar que la lista se recarga al cambiar de usuario.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this._currentSession)
      : super(
          config: const ApiConfig(baseUrl: 'http://test', wsUrl: 'ws://test'),
          tokenProvider: () => _currentSession(),
          refreshCall: (_) async => const TokenPair(
            accessToken: 'refreshed',
            refreshToken: 'refreshed',
          ),
        );

  final AuthSession Function() _currentSession;

  @override
  Future<List<Order>> myOrders() async {
    return [_orderFor(_currentSession().accessToken)];
  }
}

Order _orderFor(String token) {
  final tag = token == 'user-a' ? 'aaaaaaaa' : 'bbbbbbbb';
  return Order(
    id: '$tag-0000-0000-0000-000000000000',
    status: 'PENDING',
    customerId: token,
    pickupAddress: 'Origen',
    deliveryAddress: 'Destino',
    totalAmount: 10,
    createdAt: DateTime(2026, 1, 1),
    items: const [],
    history: const [],
  );
}

void main() {
  testWidgets('cambio de sesion no muestra pedidos del usuario anterior',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWith(
          (ref) => _FakeApiClient(
            () => ref.read(authSessionProvider) ?? AuthSession(accessToken: ''),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(authSessionProvider.notifier).state =
        AuthSession(accessToken: 'user-a', refreshToken: 'ra');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OrdersListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('#aaaaaaaa'), findsOneWidget);

    // Cambia la sesion (equivale a logout + login de otro usuario).
    container.read(authSessionProvider.notifier).state =
        AuthSession(accessToken: 'user-b', refreshToken: 'rb');
    await tester.pumpAndSettle();

    expect(find.text('#bbbbbbbb'), findsOneWidget);
    expect(find.text('#aaaaaaaa'), findsNothing);
  });
}
