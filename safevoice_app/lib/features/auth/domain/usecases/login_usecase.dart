import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String phoneNumber,
    required String password,
  }) {
    return repository.login(phoneNumber: phoneNumber, password: password);
  }
}
