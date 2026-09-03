import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;
  VerifyOtpUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String phoneNumber,
    required String otp,
  }) {
    return repository.verifyOtp(phoneNumber: phoneNumber, otp: otp);
  }
}
