import 'dart:io';

import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel(
    'com.legendarysoftware.pdf_merge_and_split/files',
  );

  static Future<void> scanFiles(List<String> paths) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('scanFiles', {'paths': paths});
    } catch (_) {
      // best-effort only
    }
  }
}
