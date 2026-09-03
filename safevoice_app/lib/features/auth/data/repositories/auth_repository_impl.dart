import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final SecureStorageService _storage;

  AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<Either<Failure, void>> register({
    required String phoneNumber,
    required String password,
    required String role,
    required String preferredLanguage,
    String? displayName,
    String? guardianChildName,
    String? guardianRelationship,
  }) async {
    try {
      await _remote.register(
        phoneNumber: phoneNumber,
        password: password,
        role: role,
        preferredLanguage: preferredLanguage,
        displayName: displayName,
        guardianChildName: guardianChildName,
        guardianRelationship: guardianRelationship,
      );
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> registerWithPin({
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
      final tokenModel = await _remote.registerWithPin(
        phoneNumber: phoneNumber,
        pin: pin,
        confirmPin: confirmPin,
        role: role,
        preferredLanguage: preferredLanguage,
        displayName: displayName,
        guardianChildName: guardianChildName,
        guardianRelationship: guardianRelationship,
      );
      await _storage.saveTokens(
        accessToken: tokenModel.accessToken,
        refreshToken: tokenModel.refreshToken,
      );
      await _storage.saveUserId(tokenModel.userId);
      await _storage.saveUserRole(tokenModel.role);
      final user = await _remote.getCurrentUser();
      return Right(user);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final tokenModel = await _remote.verifyOtp(phoneNumber: phoneNumber, otp: otp);
      await _storage.saveTokens(
        accessToken: tokenModel.accessToken,
        refreshToken: tokenModel.refreshToken,
      );
      await _storage.saveUserId(tokenModel.userId);
      await _storage.saveUserRole(tokenModel.role);

      final user = await _remote.getCurrentUser();
      return Right(user);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final tokenModel = await _remote.login(phoneNumber: phoneNumber, password: password);
      await _storage.saveTokens(
        accessToken: tokenModel.accessToken,
        refreshToken: tokenModel.refreshToken,
      );
      await _storage.saveUserId(tokenModel.userId);
      await _storage.saveUserRole(tokenModel.role);

      final user = await _remote.getCurrentUser();
      return Right(user);
    } on AccountLockedException catch (e) {
      return Left(AccountLockedFailure(e.message, e.unlocksAt));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) await _remote.logout(refreshToken);
      await _storage.clearTokens();
      return const Right(null);
    } catch (_) {
      await _storage.clearTokens();
      return const Right(null); // Best-effort logout
    }
  }

  @override
  Future<Either<Failure, void>> requestOtp(String phoneNumber) async {
    try {
      await _remote.requestOtp(phoneNumber);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _remote.resetPassword(
        phoneNumber: phoneNumber,
        otp: otp,
        newPassword: newPassword,
      );
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return const Right(null);
      final user = await _remote.getCurrentUser();
      return Right(user);
    } catch (_) {
      return const Right(null);
    }
  }
}
