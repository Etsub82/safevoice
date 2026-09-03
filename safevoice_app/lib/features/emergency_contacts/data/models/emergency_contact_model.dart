import '../../domain/entities/emergency_contact.dart';

class EmergencyContactModel extends EmergencyContact {
  const EmergencyContactModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) =>
      EmergencyContactModel(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        // backend returns 'phoneNumber' (camelCase)
        phoneNumber: (json['phoneNumber'] ?? json['phone_number'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone_number': phoneNumber,
      };
}
