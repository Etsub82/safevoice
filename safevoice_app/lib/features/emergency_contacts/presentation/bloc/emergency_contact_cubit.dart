import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/emergency_contact_repository.dart';
import '../../../../core/utils/constants.dart';
import 'emergency_contact_state.dart';

class EmergencyContactCubit extends Cubit<EmergencyContactState> {
  final EmergencyContactRepository _repository;

  EmergencyContactCubit(this._repository)
      : super(const EmergencyContactInitial());

  Future<void> loadContacts() async {
    emit(const EmergencyContactLoading());
    try {
      final contacts = await _repository.getContacts();
      emit(EmergencyContactLoaded(contacts));
    } catch (e) {
      emit(EmergencyContactError(e.toString()));
    }
  }

  Future<void> addContact({
    required String name,
    required String phoneNumber,
  }) async {
    final current = state;
    if (current is EmergencyContactLoaded &&
        current.contacts.length >= AppConstants.maxEmergencyContacts) {
      emit(const EmergencyContactError(
          'Maximum ${AppConstants.maxEmergencyContacts} emergency contacts allowed'));
      emit(current); // restore loaded state
      return;
    }
    try {
      await _repository.addContact(name: name, phoneNumber: phoneNumber);
      await loadContacts();
    } catch (e) {
      emit(EmergencyContactError(e.toString()));
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      await _repository.deleteContact(id);
      await loadContacts();
    } catch (e) {
      emit(EmergencyContactError(e.toString()));
    }
  }
}
