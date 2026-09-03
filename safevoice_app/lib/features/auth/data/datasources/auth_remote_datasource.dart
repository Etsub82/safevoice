import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<void> register({
    required String phoneNumber,
    required String password,
    required String role,
    required String preferredLanguage,
    String? displayName,
    String? guardianChildName,
    String? guardianRelationship,
  });

  /// PIN-based registration — returns tokens immediately, no OTP step.
  Future<TokenModel> registerWithPin({
    required String phoneNumber,
    required String pin,
    required String confirmPin,
    String role,
    String preferredLanguage,
    String? displayName,
    String? guardianChildName,
    String? guardianRelationship,
  });

  Future<TokenModel> verifyOtp({required String phoneNumber, required String otp});
  Future<TokenModel> login({required String phoneNumber, required String password});
  Future<TokenModel> refreshToken(String refreshToken);
  Future<void> logout(String refreshToken);
  Future<void> requestOtp(String phoneNumber);
  Future<void> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  });
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  // ── Legacy OTP register (kept for compatibility) ──────────────────────
  @override
  Future<void> register({
    required String phoneNumber,
    required String password,
    required String role,
    required String preferredLanguage,
    String? displayName,
    String? guardianChildName,
    String? guardianRelationship,
  }) async {
    try {
      await _dio.post('/api/auth/register', data: {
        'phoneNumber': phoneNumber,
        'password': password,
        'role': role,
        'preferredLanguage': preferredLanguage,
        if (displayName != null) 'displayName': displayName,
        if (guardianChildName != null) 'guardianChildName': guardianChildName,
        if (guardianRelationship != null) 'guardianRelationship': guardianRelationship,
      });
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  // ── PIN-based register (new primary victim flow) ──────────────────────
  @override
  Future<TokenModel> registerWithPin({
    required String phoneNumber,
    required String pin,
    required String confirmPin,
    String role = 'Victim',
    String preferredLanguage = 'en',
    String? displayName,
    String? guardianChildName,
    String? guardianRelationship,
  }) async {
    try {
      final res = await _dio.post('/api/auth/register-pin', data: {
        'phoneNumber': phoneNumber,
        'pin': pin,
        'confirmPin': confirmPin,
        'role': role,
        'preferredLanguage': preferredLanguage,
        if (displayName != null) 'displayName': displayName,
        if (guardianChildName != null) 'guardianChildName': guardianChildName,
        if (guardianRelationship != null) 'guardianRelationship': guardianRelationship,
      });
      return TokenModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<TokenModel> verifyOtp({required String phoneNumber, required String otp}) async {
    try {
      final res = await _dio.post('/api/auth/verify-otp', data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
      });
      return TokenModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<TokenModel> login({required String phoneNumber, required String password}) async {
    try {
      final res = await _dio.post('/api/auth/login', data: {
        'phoneNumber': phoneNumber,
        'password': password,
      });
      return TokenModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<TokenModel> refreshToken(String refreshToken) async {
    try {
      final res = await _dio.post('/api/auth/refresh', data: {'refreshToken': refreshToken});
      return TokenModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/api/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    try {
      await _dio.post('/api/auth/request-otp', data: {'phoneNumber': phoneNumber});
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/api/auth/reset-password', data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final res = await _dio.get('/api/auth/me');
      return UserModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Never _handleDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final errorCode = data is Map ? (data['error'] as String?) : null;

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw NetworkException('No internet connection. Please check your network.');
    }

    switch (status) {
      case 400:
        if (errorCode == 'PIN_MISMATCH') throw AuthException('PINs do not match.');
        if (errorCode == 'INVALID_PIN') throw AuthException('PIN must be exactly 6 digits.');
        throw AuthException(data is Map ? (data['message'] ?? 'Invalid request') : 'Invalid request');
      case 401:
        throw AuthException('INVALID_CREDENTIALS');
      case 409:
        if (errorCode == 'PHONE_IN_USE') throw AuthException('PHONE_IN_USE');
        throw AuthException('Conflict error');
      case 423:
        final unlockAt = data is Map ? (data['unlockAt'] ?? '') : '';
        throw AuthException('ACCOUNT_LOCKED:$unlockAt');
      default:
        throw ServerException(e.message ?? 'Server error');
    }
  }
}
