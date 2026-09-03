import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.phoneNumber,
    required super.role,
    super.displayName,
    required super.preferredLanguage,
    required super.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      role: _parseRole(json['role'] as String),
      displayName: json['displayName'] as String?,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static UserRole _parseRole(String r) {
    switch (r.toLowerCase()) {
      case 'guardian':
        return UserRole.guardian;
      case 'witness':
        return UserRole.witness;
      default:
        return UserRole.victim;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'role': role.name,
        'displayName': displayName,
        'preferredLanguage': preferredLanguage,
        'isActive': isActive,
      };
}
