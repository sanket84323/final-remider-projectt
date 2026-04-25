import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

/// Central Dio API client with JWT interceptor and token refresh
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  late final Dio _dio;
  bool _isRefreshing = false;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppStrings.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // ─── Request Interceptor - Attach JWT ────────────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },

      // ─── Response Interceptor - Handle 401 + token refresh ───────────────
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken != null) {
              final response = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
              final newToken = response.data['data']['accessToken'];
              final newRefresh = response.data['data']['refreshToken'];
              await _storage.write(key: 'access_token', value: newToken);
              await _storage.write(key: 'refresh_token', value: newRefresh);

              // Retry original request
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await _dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            }
          } catch (_) {
            // Refresh failed - clear tokens
            await _storage.deleteAll();
          } finally {
            _isRefreshing = false;
          }
        }
        return handler.next(error);
      },
    ));
  }

  Dio get client => _dio;

  // ─── Convenience Methods ─────────────────────────────────────────────────────
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) => _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> uploadFile(String path, FormData formData) =>
      _dio.post(path, data: formData, options: Options(contentType: 'multipart/form-data'));
}
