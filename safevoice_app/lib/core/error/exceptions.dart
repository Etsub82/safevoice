class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class AccountLockedException implements Exception {
  final String message;
  final DateTime unlocksAt;
  const AccountLockedException(this.message, this.unlocksAt);
}

class OtpExpiredException implements Exception {
  const OtpExpiredException();
}

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);
}

class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);
}

class VirusScanException implements Exception {
  final String reason;
  const VirusScanException(this.reason);
}
