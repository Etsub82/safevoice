import 'dart:io';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../utils/constants.dart';
import '../error/exceptions.dart';

/// Dio HTTP client with JWT auth interceptor and automatic token refresh.
/// Implements P7 (token expiry) and P8 (transparent refresh).
class DioClient {
  late final Dio _dio;
  final SecureStorageService _secureStorage;
  bool _isRefreshing = false;

  DioClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_secureStorage, _dio, () => _isRefreshing, (v) => _isRefreshing = v));
  }

  Dio get dio => _dio;
}

class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;
  final bool Function() _getRefreshing;
  final void Function(bool) _setRefreshing;

  _AuthInterceptor(this._storage, this._dio, this._getRefreshing, this._setRefreshing);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_getRefreshing()) {
      _setRefreshing(true);
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null) {
          _setRefreshing(false);
          return handler.reject(err);
        }

        // Attempt token refresh — P8
        final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
        final response = await refreshDio.post(
          '/api/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['accessToken'] as String;
        // Refresh endpoint may not return a new refresh token — keep the existing one
        final newRefreshToken = response.data['refreshToken'] as String? ?? refreshToken;

        await _storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Retry original request with new token
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        _setRefreshing(false);
        return handler.resolve(retryResponse);
      } catch (_) {
        _setRefreshing(false);
        // Refresh failed — P9: clear session, force re-login
        await _storage.clearTokens();
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const AuthException('Session expired. Please log in again.'),
            type: DioExceptionType.badResponse,
          ),
        );
      }
    }
    handler.next(err);
  }
}
