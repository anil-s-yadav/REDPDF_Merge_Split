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
      return Permission.manageExternalStorage.status;
    }
    return Permission.storage.status;
  }

  Future<PermissionStatus> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.granted;
    }
    final info = await DeviceInfoPlugin().androidInfo;
    if (info.version.sdkInt >= 30) {
      // For Android 11+, MANAGE_EXTERNAL_STORAGE is required to scan the entire storage for PDFs.
      // This will open a system settings page for "All files access".
      return await Permission.manageExternalStorage.request();
    }
    // Android 10 and below
    return await Permission.storage.request();
  }
}
