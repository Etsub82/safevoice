import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState { const AuthInitial(); }
class AuthLoading extends AuthState { const AuthLoading(); }

/// Emitted after phone number entered — navigate to PIN creation
class AuthPinRequired extends AuthState {
  final String phoneNumber;
  const AuthPinRequired(this.phoneNumber);
  @override List<Object?> get props => [phoneNumber];
}

/// Legacy — kept so OTP screen still works if needed
class AuthOtpSent extends AuthState {
  final String phoneNumber;
  const AuthOtpSent(this.phoneNumber);
  @override List<Object?> get props => [phoneNumber];
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState { const AuthUnauthenticated(); }

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override List<Object?> get props => [message];
}

class AuthAccountLocked extends AuthState {
  final DateTime unlocksAt;
  const AuthAccountLocked(this.unlocksAt);
  @override List<Object?> get props => [unlocksAt];
}

class AuthPasswordResetSuccess extends AuthState { const AuthPasswordResetSuccess(); }
