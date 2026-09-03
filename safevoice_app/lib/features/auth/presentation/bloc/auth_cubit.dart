import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/register_pin_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final RegisterPinUseCase _registerPinUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final AuthRepository _authRepository;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required RegisterPinUseCase registerPinUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _registerPinUseCase = registerPinUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _authRepository = authRepository,
        super(const AuthInitial()) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => user != null
          ? emit(AuthAuthenticated(user))
          : emit(const AuthUnauthenticated()),
    );
  }

  // ── PIN Registration (new primary flow) ───────────────────────────────
  Future<void> registerWithPin(RegisterPinParams params) async {
    emit(const AuthLoading());
    final result = await _registerPinUseCase(params);
    result.fold(
      (failure) => emit(AuthError(_mapFailureMessage(failure))),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  // ── Legacy OTP Registration ───────────────────────────────────────────
  Future<void> register(RegisterParams params) async {
    emit(const AuthLoading());
    final result = await _registerUseCase(params);
    result.fold(
      (failure) => emit(AuthError(_mapFailureMessage(failure))),
      (_) => emit(AuthOtpSent(params.phoneNumber)),
    );
  }

  Future<void> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    emit(const AuthLoading());
    final result = await _verifyOtpUseCase(
      phoneNumber: phoneNumber,
      otp: otp,
    );
    result.fold(
      (failure) => emit(AuthError(_mapFailureMessage(failure))),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  // ── Login (PIN = password) ────────────────────────────────────────────
  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(
      phoneNumber: phoneNumber,
      password: password,
    );
    result.fold(
      (failure) {
        if (failure is AccountLockedFailure) {
          emit(AuthAccountLocked(failure.unlocksAt));
        } else {
          emit(AuthError(_mapFailureMessage(failure)));
        }
      },
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> requestOtp(String phoneNumber) async {
    emit(const AuthLoading());
    final result = await _authRepository.requestOtp(phoneNumber);
    result.fold(
      (failure) => emit(AuthError(_mapFailureMessage(failure))),
      (_) => emit(AuthOtpSent(phoneNumber)),
    );
  }

  Future<void> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    emit(const AuthLoading());
    final result = await _authRepository.resetPassword(
      phoneNumber: phoneNumber,
      otp: otp,
      newPassword: newPassword,
    );
    result.fold(
      (failure) => emit(AuthError(_mapFailureMessage(failure))),
      (_) => emit(const AuthPasswordResetSuccess()),
    );
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  String _mapFailureMessage(Failure failure) {
    if (failure is NetworkFailure) return 'No internet connection. Please check your network.';
    if (failure is AuthFailure) return failure.message;
    if (failure is ValidationFailure) return failure.message;
    return failure.message;
  }
}
