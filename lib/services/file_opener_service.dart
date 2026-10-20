import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class FileOpenerService {
  FileOpenerService._();

  /// Opens a PDF file in the system's default external PDF reader.
  static Future<void> openPdf(BuildContext context, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found on device.')),
        );
      }
      return;
    }

    try {
      final result = await OpenFilex.open(filePath, type: 'application/pdf');
      if (result.type != ResultType.done && context.mounted) {
        final message = result.type == ResultType.noAppToOpen
            ? 'No PDF reader app found. Please install a PDF viewer.'
            : 'Could not open file: ${result.message}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }
}
