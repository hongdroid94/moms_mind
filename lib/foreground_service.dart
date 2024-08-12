import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ForegroundService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  static bool _isRunning = false;

  static Future<void> start() async {
    if (_isRunning) return;

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'foreground_service',
      '엄마의 마음 서비스',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: false,
    );

    await _notifications.show(
      888,
      '엄마의 마음',
      '백그라운드에서 실행 중입니다.',
      NotificationDetails(android: androidDetails),
    );

    _isRunning = true;
  }

  static Future<void> stop() async {
    if (!_isRunning) return;

    await _notifications.cancel(888);
    _isRunning = false;
  }
}