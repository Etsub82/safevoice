import '../entities/emergency_contact.dart';

abstract class EmergencyContactRepository {
  Future<List<EmergencyContact>> getContacts();
  Future<EmergencyContact> addContact({required String name, required String phoneNumber});
  Future<void> deleteContact(String id);
}
