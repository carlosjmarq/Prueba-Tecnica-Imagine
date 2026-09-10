import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared/shared.dart';

import '../../core/providers.dart';
import 'order_providers.dart';

typedef _ItemDraft = ({
  String name,
  String price,
  String qty,
  Uint8List? imageBytes,
  String? imageName,
  String? imageContentType,
  double? uploadProgress,
});

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

  final _items = <_ItemDraft>[];
  bool _submitting = false;

  @override
  void dispose() {
    _pickup.dispose();
    _delivery.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add((
        name: '',
        price: '',
        qty: '1',
        imageBytes: null,
        imageName: null,
        imageContentType: null,
        uploadProgress: null,
      ));
    });
  }

  static _ItemDraft _copyWithProgress(_ItemDraft item, double? progress) => (
        name: item.name,
        price: item.price,
        qty: item.qty,
        imageBytes: item.imageBytes,
        imageName: item.imageName,
        imageContentType: item.imageContentType,
        uploadProgress: progress,
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un item'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // Presign -> PUT directo a S3/MinIO con progreso por imagen.
      final api = ref.read(apiClientProvider);
      final parsed = <Map<String, dynamic>>[];
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        String? imageKey;
        final bytes = item.imageBytes;
        if (bytes != null) {
          final ct = item.imageContentType ?? 'image/webp';
          final presigned = await api.presignUpload(contentType: ct);
          await api.uploadDirect(
            url: presigned.url,
            bytes: bytes,
            contentType: ct,
            onSendProgress: (sent, total) {
              if (!mounted || total <= 0) return;
              setState(() {
                _items[i] = _copyWithProgress(_items[i], sent / total);
              });
            },
          );
          imageKey = presigned.key;
        }
        parsed.add({
          'name': item.name.trim(),
          'price': double.parse(item.price.trim()),
          'quantity': int.parse(item.qty.trim()),
          if (imageKey != null) 'image_key': imageKey,
        });
      }

      final ok = await ref.read(createOrderControllerProvider.notifier).create(
            pickupAddress: _pickup.text.trim(),
            deliveryAddress: _delivery.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            items: parsed,
          );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido creado con exito!')),
        );
        _pickup.clear();
        _delivery.clear();
        _notes.clear();
        setState(() => _items.clear());
      } else {
        final error = ref.read(createOrderControllerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                error.hasError ? error.error.toString() : 'Error al crear'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error subiendo imagen: ${ApiClient.mapError(e)}'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  onPressed: _submitting ? null : _addItem,
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
              onPressed: _submitting ? null : _submit,
              child: _submitting
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

  final _ItemDraft initial;
  final ValueChanged<_ItemDraft> onChanged;
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

  void _emit({
    Uint8List? imageBytes,
    String? imageName,
    String? imageContentType,
    bool clearImage = false,
  }) {
    widget.onChanged((
      name: _name.text,
      price: _price.text,
      qty: _qty.text,
      imageBytes: clearImage ? null : (imageBytes ?? widget.initial.imageBytes),
      imageName: clearImage ? null : (imageName ?? widget.initial.imageName),
      imageContentType: clearImage
          ? null
          : (imageContentType ?? widget.initial.imageContentType),
      uploadProgress: null,
    ));
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 70,
    );
    if (picked == null) return;
    final original = await picked.readAsBytes();
    final compressed = await compressImage(original);
    final isWebp = compressed.length < original.length;
    _emit(
      imageBytes: compressed,
      imageName: isWebp ? 'item.webp' : picked.name,
      imageContentType: isWebp ? 'image/webp' : _contentTypeFor(picked),
    );
  }

  String _contentTypeFor(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.startsWith('image/')) return mime;
    final lower = file.name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.initial.imageBytes != null;
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
                    onChanged: (_) => _emit(),
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
                    onChanged: (_) => _emit(),
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
                    onChanged: (_) => _emit(),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n <= 0) ? 'Cant.' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      widget.initial.imageBytes!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (hasImage) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(hasImage ? 'Cambiar foto' : 'Agregar foto'),
                  ),
                ),
                if (hasImage)
                  IconButton(
                    onPressed: () => _emit(clearImage: true),
                    icon: const Icon(Icons.close, color: AppColors.destructive),
                  ),
              ],
            ),
            if (widget.initial.uploadProgress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.initial.uploadProgress,
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
