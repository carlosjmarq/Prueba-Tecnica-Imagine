import 'package:dio/dio.dart';

import 'api_client.dart';

/// Factory simple para crear instancias Dio sin interceptor de auth
/// (para refresh y pruebas).
abstract final class DioClientFactory {
  static Dio create() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.current.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }
}
