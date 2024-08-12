import 'dart:io' show Platform;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:background_fetch/background_fetch.dart' as bg_fetch;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart' as workmanager;
import 'package:flutter/material.dart';
import 'package:moms_mind/gemini_service.dart';
import 'package:moms_mind/weather_service.dart';

import 'foreground_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    final AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    final IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final MacOSInitializationSettings initializationSettingsMacOS = MacOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
    );

    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    } else if (Platform.isIOS) {
      await _initBackgroundFetch();
    }

    // 저장된 알림 설정 복원
    await _restoreNotificationSettings();

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _initBackgroundFetch() async {
    await bg_fetch.BackgroundFetch.configure(
      bg_fetch.BackgroundFetchConfig(
        minimumFetchInterval: 15,  // 15분마다 실행 (iOS의 최소 간격)
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: bg_fetch.NetworkType.ANY,
      ),
      _onBackgroundFetch,
    );
  }

  void _onBackgroundFetch(String taskId) async {
    print("[BackgroundFetch] Event received: $taskId");
    await showNotification();
    bg_fetch.BackgroundFetch.finish(taskId);
  }

  Future<bool> scheduleDaily(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_hour', time.hour);
    await prefs.setInt('notification_minute', time.minute);

    if (Platform.isAndroid) {
      await ForegroundService.start();
      int id = 0;
      await AndroidAlarmManager.periodic(
        Duration(hours: 24),
        id,
        _showNotificationCallback,
        startAt: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, time.hour, time.minute),
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    } else if (Platform.isIOS) {
      // iOS에서는 BackgroundFetch가 이미 초기화되어 있으므로,
      // 여기서는 별도의 스케줄링이 필요 없습니다.
      // 대신, 앱이 백그라운드 페치 이벤트를 받을 때마다
      // 현재 시간과 설정된 알림 시간을 비교하여 처리합니다.
    }

    try {
      print("일일 알림 예약 시작");
      await workmanager.Workmanager().cancelAll();  // 기존 예약된 작업을 모두 취소
      await workmanager.Workmanager().registerPeriodicTask(
        "1",
        "showNotification",
        frequency: Duration(hours: 24),
        initialDelay: _getInitialDelay(time),
        inputData: {'hour': time.hour, 'minute': time.minute},
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.not_required,
          requiresBatteryNotLow: true,
          requiresCharging: false,
          requiresDeviceIdle: false,
        ),
      );
      print("일일 알림 예약 성공");
      return true;
    } catch (e) {
      print("일일 알림 예약 실패: $e");
      return false;
    }
  }

  Future<void> _restoreNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notification_hour');
    final minute = prefs.getInt('notification_minute');
    if (hour != null && minute != null) {
      await scheduleDaily(TimeOfDay(hour: hour, minute: minute));
    }
  }

  Duration _getInitialDelay(TimeOfDay time) {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }
    return scheduledTime.difference(now);
  }

  Future<void> showNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledHour = prefs.getInt('notification_hour') ?? 0;
      final scheduledMinute = prefs.getInt('notification_minute') ?? 0;
      final now = DateTime.now();

      // 현재 시간이 예약된 시간과 비슷한지 확인 (5분 이내의 오차 허용)
      if (now.hour == scheduledHour && (now.minute - scheduledMinute).abs() <= 5) {
        print("날씨 정보 가져오기 시작");
        final weatherInfo = await WeatherService().getCurrentWeather();
        print("날씨 정보: $weatherInfo");

        print("Gemini API 호출 시작");
        final message = await GeminiService().generateMessage(weatherInfo);
        print("생성된 메시지: $message");

        const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'mom_heart_channel',
          '엄마의 마음',
          importance: Importance.max,
          priority: Priority.high,
        );

        const IOSNotificationDetails iOSPlatformChannelSpecifics = IOSNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics,);

        print("알림 표시 시도");
        await flutterLocalNotificationsPlugin.show(0, '엄마의 마음', message, platformChannelSpecifics);
        print("알림 표시 완료");
      }
    } catch (e) {
      print("알림 표시 중 오류 발생: $e");
      throw e;  // 상위 레벨에서 오류를 처리할 수 있도록 예외를 다시 던집니다.
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _showNotificationCallback() async {
    final instance = NotificationService();
    await instance.showNotification();
  }
}