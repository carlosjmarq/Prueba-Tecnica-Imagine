import 'package:dio/dio.dart';

import '../models/models.dart';

/// Cliente HTTP central de las apps. Configurable por dart-define/env.
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    required this.wsUrl,
  });

  final String baseUrl;
  final String wsUrl;

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String _envWsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://127.0.0.1:8000',
  );

  static const ApiConfig current =
      ApiConfig(baseUrl: _envBaseUrl, wsUrl: _envWsUrl);
}

/// Error tipado del API.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthSession {
  AuthSession({required this.accessToken, this.refreshToken});

  String accessToken;
  String? refreshToken;
}

/// Cliente dio con interceptor que inyecta el Bearer token.
class ApiClient {
  ApiClient({
    required this.config,
    required AuthSession Function() tokenProvider,
    required Future<TokenPair> Function(String refreshToken) refreshCall,
    Dio? dio,
  })  : _tokenProvider = tokenProvider,
        _refreshCall = refreshCall,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenProvider().accessToken;
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final isAuth = error.requestOptions.path.contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/register');
          if (status == 401 && !isAuth) {
            final refreshed = await _tryRefresh();
            if (refreshed != null) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $refreshed';
              try {
                final retry = await _dio.fetch<dynamic>(opts);
                return handler.resolve(retry);
              } on DioException catch (e) {
                return handler.next(e);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final ApiConfig config;
  final AuthSession Function() _tokenProvider;
  final Future<TokenPair> Function(String refreshToken) _refreshCall;
  final Dio _dio;

  Future<TokenPair> login(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: {'email': email, 'password': password},
    );
    return TokenPair.fromJson(res.data!);
  }

  Future<TokenPair> register({
    required String email,
    required String fullName,
    required String password,
    required String role,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/register',
      data: {
        'email': email,
        'full_name': fullName,
        'password': password,
        'role': role
      },
    );
    return login(email, password);
  }

  Future<User> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/auth/me');
    return User.fromJson(res.data!);
  }

  Future<Order> createOrder({
    required String pickupAddress,
    required String deliveryAddress,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/orders',
      data: {
        'pickup_address': pickupAddress,
        'delivery_address': deliveryAddress,
        if (notes != null) 'notes': notes,
        'items': items,
      },
    );
    return Order.fromJson(res.data!);
  }

  Future<List<Order>> myOrders() async {
    final res = await _dio.get<List<dynamic>>('/api/v1/orders');
    return (res.data ?? [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Order>> availableOrders() async {
    final res = await _dio.get<List<dynamic>>('/api/v1/orders/available');
    return (res.data ?? [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Order>> myAssignedOrders() async {
    final res = await _dio.get<List<dynamic>>('/api/v1/orders/mine');
    return (res.data ?? [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> orderDetail(String orderId) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/orders/$orderId');
    return Order.fromJson(res.data!);
  }

  Future<Order> acceptOrder(String orderId) async {
    final res =
        await _dio.post<Map<String, dynamic>>('/api/v1/orders/$orderId/accept');
    return Order.fromJson(res.data!);
  }

  Future<Order> updateOrderStatus(
    String orderId,
    String status, {
    String? deliveryProofKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/orders/$orderId/status',
      data: {
        'status': status,
        if (deliveryProofKey != null) 'delivery_proof_key': deliveryProofKey,
      },
    );
    return Order.fromJson(res.data!);
  }

  /// Sube una imagen y devuelve su key + url (multipart/form-data).
  Future<UploadResult> uploadImage({
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType:
            contentType == null ? null : DioMediaType.parse(contentType),
      ),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/uploads/images',
      data: form,
    );
    return UploadResult.fromJson(res.data!);
  }

  /// URL del proxy autenticado de imagenes para un key de StorageService.
  String imageUrl(String key) => '${config.baseUrl}/api/v1/uploads/images/$key';

  /// Headers con el Bearer actual, para usar en `Image.network`.
  Map<String, String> authHeaders() {
    final token = _tokenProvider().accessToken;
    return token.isEmpty ? const {} : {'Authorization': 'Bearer $token'};
  }

  Future<Order> cancelOrder(String orderId) async {
    final res =
        await _dio.post<Map<String, dynamic>>('/api/v1/orders/$orderId/cancel');
    return Order.fromJson(res.data!);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/logout',
      data: {'refresh_token': refreshToken},
    );
  }

  Future<String?> _tryRefresh() async {
    final session = _tokenProvider();
    final refresh = session.refreshToken;
    if (refresh == null) return null;
    try {
      final pair = await _refreshCall(refresh);
      session.accessToken = pair.accessToken;
      session.refreshToken = pair.refreshToken;
      return pair.accessToken;
    } catch (_) {
      session.accessToken = '';
      session.refreshToken = null;
      return null;
    }
  }

  static ApiException mapError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return ApiException(data['detail'].toString(),
            statusCode: error.response?.statusCode);
      }
      return ApiException(
        switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.sendTimeout =>
            'Tiempo de espera agotado. Revisa tu conexion.',
          DioExceptionType.connectionError =>
            'No se pudo conectar con el servidor.',
          _ => 'Error de red (${error.response?.statusCode ?? '?'}).',
        },
        statusCode: error.response?.statusCode,
      );
    }
    return ApiException(error.toString());
  }
}
