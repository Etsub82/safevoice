import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class AppConstants {
  static String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://safevoice-api.onrender.com',
  );

  static String get baseUrl => _baseUrl;

  static Future<void> loadConfig() async {
    // Step 1: load from config.json
    try {
      final raw = await rootBundle.loadString('assets/config.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final url = json['api_base_url'] as String?;
      if (url != null && url.isNotEmpty) _baseUrl = url;
    } catch (_) {}

    // Step 2: verify it works, if not scan local subnet quickly
    if (!await _isReachable(_baseUrl)) {
      final found = await _quickScan();
      if (found != null) {
        _baseUrl = found;
        // Update config.json in memory for this session
      }
    }
  }

  static Future<bool> _isReachable(String url) async {
    try {
      final uri = Uri.parse(url);
      final socket = await Socket.connect(
        uri.host, uri.port,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> _quickScan() async {
    // Get current device's own IP to determine subnet
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    final subnets = <String>{};
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        final parts = addr.address.split('.');
        if (parts.length == 4) {
          subnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
        }
      }
    }

    // Try common router-assigned IPs first (1-20) on detected subnets
    for (final subnet in subnets) {
      for (int i = 1; i <= 20; i++) {
        final candidate = 'http://$subnet.$i:5000';
        if (await _isReachable(candidate)) return candidate;
      }
    }
    return null;
  }

  // Auth
  static const int jwtExpiryMinutes = 60;
  static const int refreshTokenExpiryDays = 7;
  static const int otpExpiryMinutes = 10;
  static const int maxLoginAttempts = 5;
  static const int lockoutMinutes = 30;
  static const int sessionIdleMinutes = 5;

  // SOS
  static const int sosCountdownSeconds = 10;
  static const int maxEmergencyContacts = 5;

  // Location
  static const int locationPingIntervalSeconds = 30;
  static const int locationPurgeDaysAfterClosure = 30;

  // Evidence
  static const int maxFileSizeBytes = 100 * 1024 * 1024;
  static const int maxTotalEvidenceBytes = 500 * 1024 * 1024;

  // Offline queue
  static const int maxSyncAttempts = 3;
  static const List<int> retryBackoffSeconds = [5, 30, 120];

  // Storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keySelectedLanguage = 'selected_language';
  static const String keyDbEncryptionKey = 'db_encryption_key';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyFcmToken = 'fcm_token';

  // Supported locales
  static const List<String> supportedLanguageCodes = ['en', 'am', 'om', 'ti', 'so'];
  static const Map<String, String> languageNames = {
    'en': 'English',
    'am': 'አማርኛ (Amharic)',
    'om': 'Oromifaa',
    'ti': 'ትግርኛ (Tigrinya)',
    'so': 'Soomaali (Somali)',
  };
}
