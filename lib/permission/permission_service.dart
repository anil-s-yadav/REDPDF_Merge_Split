import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<PermissionStatus> checkStoragePermission() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.granted;
    }
    return Permission.storage.status;
  }

  Future<PermissionStatus> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.granted;
    }
    return Permission.storage.request();
  }
}

