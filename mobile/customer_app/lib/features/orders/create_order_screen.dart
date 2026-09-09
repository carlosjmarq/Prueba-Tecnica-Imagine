import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

import 'order_providers.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickup = TextEditingController();
  final _delivery = TextEditingController();
  final _notes = TextEditingController();

  final _items = <({String name, String price, String qty})>[];

  @override
  void dispose() {
    _pickup.dispose();
    _delivery.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add((name: '', price: '', qty: '1'));
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final parsed = <Map<String, dynamic>>[];
    for (final item in _items) {
      parsed.add({
        'name': item.name.trim(),
        'price': double.parse(item.price.trim()),
        'quantity': int.parse(item.qty.trim()),
      });
    }
    if (parsed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un item'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }
    final controller = ref.read(createOrderControllerProvider.notifier);
    final ok = await controller.create(
      pickupAddress: _pickup.text.trim(),
      deliveryAddress: _delivery.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      items: parsed,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido creado con exito!')),
      );
      _pickup.clear();
      _delivery.clear();
      _notes.clear();
      setState(() => _items.clear());
    } else if (mounted) {
      final error = ref.read(createOrderControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(error.hasError ? error.error.toString() : 'Error al crear'),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loading = ref.watch(createOrderControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear pedido')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Nuevo pedido', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pickup,
              decoration:
                  const InputDecoration(labelText: 'Direccion de recogida'),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Direccion requerida'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _delivery,
              decoration:
                  const InputDecoration(labelText: 'Direccion de entrega'),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Direccion requerida'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items', style: theme.textTheme.titleLarge),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar item'),
                ),
              ],
            ),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Sin items. Usa "Agregar item" para incluir productos.',
                  style: theme.textTheme.bodySmall,
                ),
              )
            else
              for (var i = 0; i < _items.length; i++)
                _ItemEditor(
                  key: ValueKey(i),
                  initial: _items[i],
                  onChanged: (v) => setState(() => _items[i] = v),
                  onRemove: () => setState(() => _items.removeAt(i)),
                ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : const Text('Crear pedido'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.onRemove,
  });

  final ({String name, String price, String qty}) initial;
  final ValueChanged<({String name, String price, String qty})> onChanged;
  final VoidCallback onRemove;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late final _name = TextEditingController(text: widget.initial.name);
  late final _price = TextEditingController(text: widget.initial.price);
  late final _qty = TextEditingController(text: widget.initial.qty);

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    onChanged: (v) => widget.onChanged(
                        (name: v, price: _price.text, qty: _qty.text)),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Nombre' : null,
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.destructive),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'Precio'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => widget.onChanged(
                        (name: _name.text, price: v, qty: _qty.text)),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n <= 0) ? 'Precio invalido' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _qty,
                    decoration: const InputDecoration(labelText: 'Cant.'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => widget.onChanged(
                        (name: _name.text, price: _price.text, qty: v)),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n <= 0) ? 'Cant.' : null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
