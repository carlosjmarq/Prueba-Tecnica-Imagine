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
    void Function(AuthSession session)? onSessionRefreshed,
    Dio? dio,
  })  : _tokenProvider = tokenProvider,
        _refreshCall = refreshCall,
        _onSessionRefreshed = onSessionRefreshed,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 60),
                receiveTimeout: const Duration(seconds: 30),
              ),
            ),
        // Sin interceptor de auth: los PUT directos a S3/MinIO llevan la firma
        // en la URL, no un header Authorization (romperia la firma).
        _directDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 120),
            receiveTimeout: const Duration(seconds: 60),
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
  final void Function(AuthSession session)? _onSessionRefreshed;
  final Dio _dio;
  final Dio _directDio;
  Future<String?>? _refreshInFlight;

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

  /// Pide una URL firmada (PUT) para subir una imagen directo a S3/MinIO.
  Future<UploadResult> presignUpload({required String contentType}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/uploads/presign',
      data: {'content_type': contentType},
    );
    return UploadResult.fromJson(res.data!);
  }

  /// Sube bytes directo a la URL firmada (S3/MinIO). Reintenta con backoff.
  Future<void> uploadDirect({
    required String url,
    required List<int> bytes,
    required String contentType,
    void Function(int sent, int total)? onSendProgress,
  }) {
    return _withRetry<void>(() => _directDio.put<void>(
          url,
          data: bytes,
          options: Options(contentType: contentType),
          onSendProgress: onSendProgress,
        ));
  }

  /// Sube una imagen y devuelve su key + url (multipart/form-data, fallback).
  Future<UploadResult> uploadImage({
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) {
    return _withRetry(() async {
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
    });
  }

  Future<T> _withRetry<T>(Future<T> Function() action) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        if (!_isRetryable(e) || attempt == 2) rethrow;
        // Exponential backoff: 500ms, 1s, 2s.
        await Future<void>.delayed(
            Duration(milliseconds: 500 * (1 << attempt)));
      }
    }
    throw lastError!;
  }

  bool _isRetryable(Object error) {
    if (error is! DioException) return false;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      _ => (error.response?.statusCode ?? 0) >= 500,
    };
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

  /// Renueva la sesion si es posible (deduplicado). Expuesto para el WS.
  Future<bool> ensureFreshToken() async => (await _tryRefresh()) != null;

  /// Una sola renovacion en vuelo: evita que 401 concurrentes roten el mismo
  /// refresh token y que uno de ellos invalide la sesion.
  Future<String?> _tryRefresh() {
    return _refreshInFlight ??=
        _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<String?> _doRefresh() async {
    final session = _tokenProvider();
    final refresh = session.refreshToken;
    if (refresh == null) return null;
    try {
      final pair = await _refreshCall(refresh);
      session.accessToken = pair.accessToken;
      session.refreshToken = pair.refreshToken;
      _onSessionRefreshed?.call(session);
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
