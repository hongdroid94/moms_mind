import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:moms_mind/notification_service.dart';
import 'package:moms_mind/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final permissionService = PermissionService();
  final permissionStatus = await permissionService.requestAllPermissions();

  if (permissionStatus[Permission.location]!.isGranted &&
      permissionStatus[Permission.notification]!.isGranted) {
    try {
      await NotificationService().init();
      await Workmanager().initialize(callbackDispatcher);
      if (Platform.isAndroid) {
        await AndroidAlarmManager.initialize();
      }
      // iOS를 위한 BackgroundFetch 초기화는 NotificationService().init() 내에서 처리됩니다.
    } catch (e) {
      print('Initialization failed: $e');
    }
  } else {
    print('필요한 권한이 승인되지 않았습니다.');
    // 여기서 사용자에게 권한이 필요하다는 메시지를 표시할 수 있습니다.
  }

  runApp(MyApp());
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("백그라운드 태스크 시작: $task");
    try {
      await NotificationService().showNotification();
      print("알림 전송 완료");
      return Future.value(true);
    } catch (e) {
      print("알림 전송 실패: $e");
      return Future.value(false);
    }
  });
}

// iOS를 위한 백그라운드 페치 콜백
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }

  await NotificationService().showNotification();
  BackgroundFetch.finish(taskId);
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '엄마의 마음',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final PermissionService _permissionService = PermissionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('엄마의 마음')),
      body: Center(
        child: ElevatedButton(
          child: Text('알림 시간 설정'),
          onPressed: () => _checkPermissionsAndShowTimePicker(context),
        ),
      ),
    );
  }

  void _checkPermissionsAndShowTimePicker(BuildContext context) async {
    bool locationGranted = await _permissionService.requestLocationPermission();
    bool notificationGranted = await _permissionService.requestNotificationPermission();

    if (locationGranted && notificationGranted) {
      _showTimePickerDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 및 알림 권한이 필요합니다.')),
      );
    }
  }

  void _showTimePickerDialog(BuildContext context) async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      print("선택된 시간: ${selectedTime.format(context)}");
      bool scheduled = await NotificationService().scheduleDaily(selectedTime);
      if (scheduled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림이 ${selectedTime.format(context)}에 설정되었습니다.')),
        );
        print("알림 예약 성공");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림 설정에 실패했습니다.')),
        );
        print("알림 예약 실패");
      }
    }
  }
}