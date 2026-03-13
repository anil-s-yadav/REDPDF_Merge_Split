import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'permission_service.dart';

class PermissionProvider with ChangeNotifier {
  final PermissionService _service = PermissionService();

  PermissionStatus _storageStatus = PermissionStatus.denied;

  PermissionStatus get storageStatus => _storageStatus;
  bool get isStorageGranted => _storageStatus.isGranted;
  bool get isStoragePermanentlyDenied => _storageStatus.isPermanentlyDenied;

  Future<PermissionStatus> checkStoragePermission() async {
    _storageStatus = await _service.checkStoragePermission();
    notifyListeners();
    return _storageStatus;
  }

  Future<PermissionStatus> requestStoragePermission() async {
    _storageStatus = await _service.requestStoragePermission();
    notifyListeners();
    return _storageStatus;
  }

  /// Ensure storage permission.
  /// - Checks current status
  /// - Requests permission if not granted
  /// Returns the final [PermissionStatus].
  Future<PermissionStatus> ensureStoragePermission() async {
    final current = await checkStoragePermission();
    if (current.isGranted) return current;

    debugPrint('Requesting storage permission...');
    final result = await requestStoragePermission();
    debugPrint('Permission result: $result');
    return result;
  }
}
