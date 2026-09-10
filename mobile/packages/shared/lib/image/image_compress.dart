import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Comprime una imagen a WebP antes de subirla (payload mas ligero y rapido).
/// Devuelve los bytes originales si la compresion falla o no reduce.
Future<Uint8List> compressImage(Uint8List bytes, {int quality = 70}) async {
  try {
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      quality: quality,
      format: CompressFormat.webp,
    );
    if (compressed.isNotEmpty && compressed.length < bytes.length) {
      return compressed;
    }
  } catch (_) {}
  return bytes;
}
