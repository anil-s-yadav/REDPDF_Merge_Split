import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<PermissionStatus> checkStoragePermission() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.granted;
    }
    final info = await DeviceInfoPlugin().androidInfo;
    if (info.version.sdkInt >= 30) {
      // Scoped storage handles file access on Android 11+
      return PermissionStatus.granted;
    }
    return Permission.storage.status;
  }

  Future<PermissionStatus> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.granted;
    }
    final info = await DeviceInfoPlugin().androidInfo;
    if (info.version.sdkInt >= 30) {
      // No need to request permissions on Android 11+ for picking files or using app-specific directories
      return PermissionStatus.granted;
    }
    // Android 10 and below
    return await Permission.storage.request();
  }
}
