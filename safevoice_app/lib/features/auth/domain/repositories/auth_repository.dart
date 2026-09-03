import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Legacy OTP-based register (kept for compatibility)
  Future<Either<Failure, void>> register({
    required String phoneNumber,
    required String password,
    required String role,
    required String preferredLanguage,
    String? displayName,
    String? guardianChildName,
    String? guardianRelationship,
  });

  /// PIN-based registration — no OTP. Returns authenticated User immediately.
  Future<Either<Failure, User>> registerWithPin({
    required String phoneNumber,
    required String pin,
    required String confirmPin,
    String role,
    String preferredLanguage,
    String? displayName,
    String? guardianChildName,
    String? guardianRelationship,
  });

  Future<Either<Failure, User>> verifyOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<Either<Failure, User>> login({
    required String phoneNumber,
    required String password,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  });

  Future<Either<Failure, void>> requestOtp(String phoneNumber);

  Future<Either<Failure, User?>> getCurrentUser();
}
