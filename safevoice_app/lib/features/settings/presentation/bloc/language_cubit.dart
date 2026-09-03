import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/constants.dart';

class LanguageState extends Equatable {
  final Locale locale;
  final String languageCode;

  const LanguageState({required this.locale, required this.languageCode});

  @override
  List<Object?> get props => [locale, languageCode];
}

class LanguageCubit extends Cubit<LanguageState> {
  final SecureStorageService _storage;

  LanguageCubit(this._storage)
      : super(const LanguageState(locale: Locale('en'), languageCode: 'en'));

  Future<void> loadSavedLanguage() async {
    final saved = await _storage.getLanguage();
    if (saved != null && AppConstants.supportedLanguageCodes.contains(saved)) {
      emit(LanguageState(locale: Locale(saved), languageCode: saved));
    }
  }

  Future<void> changeLanguage(String code) async {
    if (!AppConstants.supportedLanguageCodes.contains(code)) return;
    await _storage.saveLanguage(code);
    emit(LanguageState(locale: Locale(code), languageCode: code));
  }
}
