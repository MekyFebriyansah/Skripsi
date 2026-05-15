import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await LocalNotificationService.initialize();
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await LocalNotificationService.initialize();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;

      await LocalNotificationService.showMessageNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notification.title ?? 'Pesan baru',
        body: notification.body ?? 'Anda menerima notifikasi baru',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notifikasi dibuka: ${message.data}');
    });

    _messaging.onTokenRefresh.listen((token) async {
      await _sendTokenToServer(token);
    });

    _initialized = true;
  }

  static Future<void> syncTokenToServer() async {
    if (kIsWeb) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _sendTokenToServer(token);
  }

  static Future<void> _sendTokenToServer(String token) async {
    try {
      final authToken = await ApiService.getToken();
      if (authToken == null || authToken.isEmpty) return;

      await ApiService.updateFcmToken(token);
    } catch (_) {
      // Gagal sinkron token tidak boleh mengganggu aplikasi.
    }
  }
}
