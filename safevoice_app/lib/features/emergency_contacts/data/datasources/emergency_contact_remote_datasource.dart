import 'package:dio/dio.dart';
import '../models/emergency_contact_model.dart';

abstract class EmergencyContactRemoteDataSource {
  Future<List<EmergencyContactModel>> getContacts();
  Future<EmergencyContactModel> addContact({required String name, required String phoneNumber});
  Future<void> deleteContact(String id);
}

class EmergencyContactRemoteDataSourceImpl
    implements EmergencyContactRemoteDataSource {
  final Dio _dio;

  EmergencyContactRemoteDataSourceImpl(this._dio);

  static const _base = '/api/users/me/emergency-contacts';

  @override
  Future<List<EmergencyContactModel>> getContacts() async {
    final res = await _dio.get(_base);
    return (res.data as List)
        .map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EmergencyContactModel> addContact({
    required String name,
    required String phoneNumber,
  }) async {
    final res = await _dio.post(_base, data: {
      'name': name,
      'phoneNumber': phoneNumber,
    });
    return EmergencyContactModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteContact(String id) =>
      _dio.delete('$_base/$id');
}
