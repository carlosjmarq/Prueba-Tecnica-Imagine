library shared;

export 'models/models.dart';
export 'network/api_client.dart';
export 'network/dio_factory.dart';
export 'realtime/order_socket.dart';
export 'image/image_compress.dart';
export 'theme/app_theme.dart';

/// Formatea un monto como moneda local simple.
String formatMoney(double amount) {
  return '\$${amount.toStringAsFixed(2)}';
}
