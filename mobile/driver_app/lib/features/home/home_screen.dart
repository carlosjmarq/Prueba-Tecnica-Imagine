import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../auth/auth_providers.dart';
import '../orders/order_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realtimeListenerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    const screens = [
      AvailableOrdersView(),
      MyOrdersView(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.inbox_outlined), label: 'Disponibles'),
          NavigationDestination(
              icon: Icon(Icons.delivery_dining_outlined), label: 'Mis pedidos'),
        ],
      ),
    );
  }
}

/// Lista de pedidos disponibles para aceptar.
class AvailableOrdersView extends ConsumerWidget {
  const AvailableOrdersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(availableOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No hay pedidos pendientes.\nEsperando nuevos...',
                  textAlign: TextAlign.center),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(availableOrdersProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _AvailableCard(order: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _AvailableCard extends ConsumerWidget {
  const _AvailableCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final busy = ref.watch(orderActionControllerProvider).isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('#${order.id.substring(0, 8)}',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 16, color: AppColors.secondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${order.pickupAddress} -> ${order.deliveryAddress}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                '${order.items.length} item(s)  |  ${formatMoney(order.totalAmount)}'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy
                    ? null
                    : () async {
                        final ok = await ref
                            .read(orderActionControllerProvider.notifier)
                            .accept(order.id);
                        if (!ok && context.mounted) {
                          final err = ref.read(orderActionControllerProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err.hasError
                                  ? err.error.toString()
                                  : 'No se pudo aceptar'),
                              backgroundColor: AppColors.destructive,
                            ),
                          );
                        }
                      },
                child: const Text('Aceptar pedido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pedidos asignados con acciones de actualizar estado.
class MyOrdersView extends ConsumerWidget {
  const MyOrdersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
                child: Text('Aun no tienes pedidos asignados.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myOrdersProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _MyOrderCard(order: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _MyOrderCard extends ConsumerWidget {
  const _MyOrderCard({required this.order});

  final Order order;

  Future<void> _advance(BuildContext context, WidgetRef ref) async {
    final next = switch (order.status) {
      'ACCEPTED' => 'PICKED_UP',
      'PICKED_UP' => 'DELIVERED',
      _ => null,
    };
    if (next == null) return;
    final ok = await ref
        .read(orderActionControllerProvider.notifier)
        .updateStatus(order.id, next);
    if (!ok && context.mounted) {
      final err = ref.read(orderActionControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              err.hasError ? err.error.toString() : 'No se pudo actualizar'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = orderStatusColor(order.status);
    final busy = ref.watch(orderActionControllerProvider).isLoading;
    final canAdvance =
        order.status == 'ACCEPTED' || order.status == 'PICKED_UP';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${order.id.substring(0, 8)}',
                    style: theme.textTheme.titleLarge),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    orderStatusLabel(order.status),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.pickupAddress} -> ${order.deliveryAddress}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
                '${formatMoney(order.totalAmount)}  |  ${order.items.length} item(s)'),
            if (canAdvance) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : () => _advance(context, ref),
                  child: Text(
                    order.status == 'ACCEPTED'
                        ? 'Marcar como recogido'
                        : 'Marcar como entregado',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
