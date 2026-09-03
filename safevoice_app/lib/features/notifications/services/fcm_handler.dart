import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/constants.dart';

/// Handles Firebase Cloud Messaging token registration and message routing.
/// Implements Req 13.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages — cache status update locally
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FCMHandler {
  FCMHandler._();
  static final FCMHandler instance = FCMHandler._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final SecureStorageService _storage = SecureStorageService();

  /// Called once on app start.
  Future<void> initialize() async {
    // Request permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get and persist FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _storage.saveFcmToken(token);
      debugPrint('[FCM] Token registered: ${token.substring(0, 20)}...');
    }

    // Token refresh listener
    _messaging.onTokenRefresh.listen((newToken) async {
      await _storage.saveFcmToken(newToken);
      // TODO: POST /api/devices/register with new token
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTapped);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final data = message.data;
    debugPrint('[FCM] Foreground message: ${data['event_type']}');
    // TODO: dispatch to relevant Cubit based on event_type
    // e.g. CASE_STATUS_CHANGED → CaseListCubit.refresh()
  }

  void _onNotificationTapped(RemoteMessage message) {
    final deepLink = message.data['deep_link'] as String?;
    if (deepLink != null) {
      NotificationDeepLinkRouter.navigate(deepLink);
    }
  }
}

/// Routes FCM deep links to the correct screen. Implements Req 13.5.
class NotificationDeepLinkRouter {
  static void Function(String)? _navigator;

  static void setNavigator(void Function(String) fn) {
    _navigator = fn;
  }

  static void navigate(String deepLink) {
    _navigator?.call(deepLink);
  }
}
