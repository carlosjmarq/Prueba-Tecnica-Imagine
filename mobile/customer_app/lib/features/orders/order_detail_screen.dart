import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import '../../core/providers.dart';
import 'order_providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailProvider(orderId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del pedido')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          final color = orderStatusColor(order.status);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pedido #${order.id.substring(0, 8)}',
                      style: theme.textTheme.headlineSmall),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withAlpha(31),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      orderStatusLabel(order.status),
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row(Icons.place_outlined, 'Recogida',
                          order.pickupAddress),
                      const SizedBox(height: 8),
                      _row(Icons.place, 'Entrega', order.deliveryAddress),
                      if (order.notes != null) ...[
                        const SizedBox(height: 8),
                        _row(Icons.notes, 'Notas', order.notes!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Items', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: order.items
                        .map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  if (item.imageKey != null) ...[
                                    _RemoteImage(
                                        imageKey: item.imageKey!, size: 40),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child:
                                        Text('${item.quantity} x ${item.name}'),
                                  ),
                                  Text(formatMoney(item.total)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleLarge),
                      Text(
                        formatMoney(order.totalAmount),
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              if (order.deliveryProofKey != null) ...[
                const SizedBox(height: 16),
                Text('Comprobante de entrega',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _RemoteImage(
                          imageKey: order.deliveryProofKey!, size: 160),
                    ),
                  ),
                ),
              ],
              if (order.isPending) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final api = ref.read(apiClientProvider);
                    try {
                      await api.cancelOrder(order.id);
                      ref.invalidate(orderDetailProvider(orderId));
                      ref.invalidate(myOrdersProvider);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(ApiClient.mapError(e).message),
                          backgroundColor: AppColors.destructive,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar pedido'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppColors.foreground, fontSize: 14),
              children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Miniatura de una imagen servida por el proxy autenticado del backend.
class _RemoteImage extends ConsumerWidget {
  const _RemoteImage({required this.imageKey, required this.size});

  final String imageKey;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiClientProvider);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        api.imageUrl(imageKey),
        headers: api.authHeaders(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: AppColors.muted,
          child: const Icon(Icons.broken_image_outlined,
              size: 20, color: AppColors.secondary),
        ),
      ),
    );
  }
}
