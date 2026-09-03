import 'package:equatable/equatable.dart';

abstract class SosState extends Equatable {
  const SosState();
  @override
  List<Object?> get props => [];
}

class SosIdle extends SosState {
  const SosIdle();
}

class SosCountdown extends SosState {
  final int secondsRemaining;
  const SosCountdown(this.secondsRemaining);
  @override
  List<Object?> get props => [secondsRemaining];
}

class SosSending extends SosState {
  const SosSending();
}

class SosSent extends SosState {
  final String sosId;
  const SosSent(this.sosId);
  @override
  List<Object?> get props => [sosId];
}

class SosCancelled extends SosState {
  const SosCancelled();
}

class SosPendingOffline extends SosState {
  const SosPendingOffline();
}

class SosError extends SosState {
  final String message;
  const SosError(this.message);
  @override
  List<Object?> get props => [message];
}
