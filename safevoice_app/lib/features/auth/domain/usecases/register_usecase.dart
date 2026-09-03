import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String phoneNumber;
  final String password;
  final String role;
  final String preferredLanguage;
  final String? displayName;
  final String? guardianChildName;
  final String? guardianRelationship;

  const RegisterParams({
    required this.phoneNumber,
    required this.password,
    required this.role,
    required this.preferredLanguage,
    this.displayName,
    this.guardianChildName,
    this.guardianRelationship,
  });
}

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  Future<Either<Failure, void>> call(RegisterParams params) {
    return repository.register(
      phoneNumber: params.phoneNumber,
      password: params.password,
      role: params.role,
      preferredLanguage: params.preferredLanguage,
      displayName: params.displayName,
      guardianChildName: params.guardianChildName,
      guardianRelationship: params.guardianRelationship,
    );
  }
}
