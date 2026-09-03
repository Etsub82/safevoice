import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

/// Wraps flutter_secure_storage for typed access to all persisted secrets.
/// On Android: uses Android Keystore. On iOS: uses Secure Enclave / Keychain.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.keyAccessToken, value: accessToken),
      _storage.write(key: AppConstants.keyRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.keyAccessToken);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.keyRefreshToken);

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AppConstants.keyAccessToken),
      _storage.delete(key: AppConstants.keyRefreshToken),
    ]);
  }

  Future<void> saveLanguage(String code) =>
      _storage.write(key: AppConstants.keySelectedLanguage, value: code);

  Future<String?> getLanguage() =>
      _storage.read(key: AppConstants.keySelectedLanguage);

  Future<void> saveUserId(String id) =>
      _storage.write(key: AppConstants.keyUserId, value: id);

  Future<String?> getUserId() =>
      _storage.read(key: AppConstants.keyUserId);

  Future<void> saveUserRole(String role) =>
      _storage.write(key: AppConstants.keyUserRole, value: role);

  Future<String?> getUserRole() =>
      _storage.read(key: AppConstants.keyUserRole);

  /// DB encryption key — generated once, stored in Keystore/Keychain.
  Future<String?> getDbEncryptionKey() =>
      _storage.read(key: AppConstants.keyDbEncryptionKey);

  Future<void> saveDbEncryptionKey(String key) =>
      _storage.write(key: AppConstants.keyDbEncryptionKey, value: key);

  Future<void> saveFcmToken(String token) =>
      _storage.write(key: AppConstants.keyFcmToken, value: token);

  Future<String?> getFcmToken() =>
      _storage.read(key: AppConstants.keyFcmToken);

  Future<void> clearAll() => _storage.deleteAll();
}
