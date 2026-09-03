import 'package:equatable/equatable.dart';

enum UserRole { victim, guardian, witness }

class User extends Equatable {
  final String id;
  final String phoneNumber;
  final UserRole role;
  final String? displayName;
  final String preferredLanguage;
  final bool isActive;

  const User({
    required this.id,
    required this.phoneNumber,
    required this.role,
    this.displayName,
    required this.preferredLanguage,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, phoneNumber, role, displayName, preferredLanguage, isActive];
}
