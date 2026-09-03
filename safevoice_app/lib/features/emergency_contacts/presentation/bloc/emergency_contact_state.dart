import 'package:equatable/equatable.dart';
import '../../domain/entities/emergency_contact.dart';

abstract class EmergencyContactState extends Equatable {
  const EmergencyContactState();
  @override
  List<Object?> get props => [];
}

class EmergencyContactInitial extends EmergencyContactState {
  const EmergencyContactInitial();
}

class EmergencyContactLoading extends EmergencyContactState {
  const EmergencyContactLoading();
}

class EmergencyContactLoaded extends EmergencyContactState {
  final List<EmergencyContact> contacts;
  const EmergencyContactLoaded(this.contacts);
  @override
  List<Object?> get props => [contacts];
}

class EmergencyContactError extends EmergencyContactState {
  final String message;
  const EmergencyContactError(this.message);
  @override
  List<Object?> get props => [message];
}
