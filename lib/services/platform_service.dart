import 'dart:io';

import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel(
    'com.legendarysoftware.marge_pdf_split_pdf/files',
  );

  static Future<void> scanFiles(List<String> paths) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('scanFiles', {'paths': paths});
    } catch (_) {
      // best-effort only
    }
  }

  static Future<String?> saveToDownloads(String tempPath, String fileName) async {
    if (!Platform.isAndroid) return null;
    try {
      final String? result = await _channel.invokeMethod<String>('saveToDownloads', {
        'filePath': tempPath,
        'fileName': fileName,
      });
      return result;
    } catch (e) {
      return null;
    }
  }
}
