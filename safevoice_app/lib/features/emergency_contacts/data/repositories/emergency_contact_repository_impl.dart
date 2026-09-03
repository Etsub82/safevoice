import '../../domain/entities/emergency_contact.dart';
import '../../domain/repositories/emergency_contact_repository.dart';
import '../datasources/emergency_contact_remote_datasource.dart';

class EmergencyContactRepositoryImpl implements EmergencyContactRepository {
  final EmergencyContactRemoteDataSource _remote;

  EmergencyContactRepositoryImpl(this._remote);

  @override
  Future<List<EmergencyContact>> getContacts() => _remote.getContacts();

  @override
  Future<EmergencyContact> addContact({
    required String name,
    required String phoneNumber,
  }) =>
      _remote.addContact(name: name, phoneNumber: phoneNumber);

  @override
  Future<void> deleteContact(String id) => _remote.deleteContact(id);
}
