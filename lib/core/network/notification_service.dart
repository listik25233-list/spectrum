import 'dart:io';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Future<void> showStorageAlert(String message) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final androidDetails = AndroidNotificationDetails(
      'storage_alerts',
      'Storage Alerts',
      channelDescription: 'Notifications for disk usage and cache limits',
      importance: Importance.high,
      priority: Priority.high,
      colorized: true,
      color: const Color(0xFF7C3AED),
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notifications.show(
      99, // Unique ID for storage alerts
      'STORAGE_CAPACITY_ALERT',
      message,
      notificationDetails,
    );
  }
}
