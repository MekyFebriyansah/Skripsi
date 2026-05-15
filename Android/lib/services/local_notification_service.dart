import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _messageChannel =
      AndroidNotificationChannel(
    'chat_messages_channel',
    'Pesan Chat Pengaduan',
    description: 'Notifikasi pesan baru antara admin dan user',
    importance: Importance.max,
  );

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(initSettings);

    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(_messageChannel);

    _initialized = true;
  }

  static Future<void> requestPermission() async {
    if (kIsWeb) return;

    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  static Future<void> showMessageNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'chat_messages_channel',
      'Pesan Chat Pengaduan',
      channelDescription: 'Notifikasi pesan baru antara admin dan user',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Pesan baru',
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }
}
