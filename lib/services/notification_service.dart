import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request notification permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification permission granted');
    }

    // Get FCM token for push notifications
    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      // Could show in-app notification here
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    // Subscribe to nearby alerts topic
    await _messaging.subscribeToTopic('nearby_alerts');
  }

  // Subscribe to city-specific topics for targeted notifications
  Future<void> subscribeToCity(String city) async {
    final normalizedCity = city.toLowerCase().replaceAll(' ', '_');
    await _messaging.subscribeToTopic('city_$normalizedCity');
  }

  Future<void> unsubscribeFromCity(String city) async {
    final normalizedCity = city.toLowerCase().replaceAll(' ', '_');
    await _messaging.unsubscribeFromTopic('city_$normalizedCity');
  }
}

// Must be top-level function
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}
