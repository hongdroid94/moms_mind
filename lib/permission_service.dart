import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class PermissionService {
  Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt != null && sdkInt >= 33) {
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          status = await Permission.notification.request();
        }
        return status.isGranted;
      } else {
        // Android 12 이하에서는 알림 권한이 자동으로 부여됩니다.
        return true;
      }
    } else if (Platform.isIOS) {
      var status = await Permission.notification.status;
      if (!status.isGranted) {
        status = await Permission.notification.request();
      }
      return status.isGranted;
    }
    return false;
  }

  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    List<Permission> permissions = [Permission.location];

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt != null && sdkInt >= 33) {
        permissions.add(Permission.notification);
      }
    } else if (Platform.isIOS) {
      permissions.add(Permission.notification);
    }

    return await permissions.request();
  }
}