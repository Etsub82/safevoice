import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterPinParams {
  final String phoneNumber;
  final String pin;
  final String confirmPin;
  final String role;
  final String preferredLanguage;
  final String? displayName;
  final String? guardianChildName;
  final String? guardianRelationship;

  const RegisterPinParams({
    required this.phoneNumber,
    required this.pin,
    required this.confirmPin,
    this.role = 'Victim',
    this.preferredLanguage = 'en',
    this.displayName,
    this.guardianChildName,
    this.guardianRelationship,
  });
}

class RegisterPinUseCase {
  final AuthRepository repository;
  RegisterPinUseCase(this.repository);

  Future<Either<Failure, User>> call(RegisterPinParams params) {
    return repository.registerWithPin(
      phoneNumber: params.phoneNumber,
      pin: params.pin,
      confirmPin: params.confirmPin,
      role: params.role,
      preferredLanguage: params.preferredLanguage,
      displayName: params.displayName,
      guardianChildName: params.guardianChildName,
      guardianRelationship: params.guardianRelationship,
    );
  }
}
