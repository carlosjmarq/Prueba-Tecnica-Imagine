import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'order_providers.dart';
import 'order_detail_screen.dart';

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child:
                Text('Error al cargar: $e', style: theme.textTheme.bodyMedium),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                'Aun no tienes pedidos.\nCrea uno desde la pestana Crear.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myOrdersProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final order = list[i];
                return _OrderCard(order: order);
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = orderStatusColor(order.status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: order.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.id.substring(0, 8)}',
                    style: theme.textTheme.titleLarge,
                  ),
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
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
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
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} item(s)',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    formatMoney(order.totalAmount),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
