import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String path;
  final String? title;

  const PdfViewerScreen({super.key, required this.path, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'PDF Viewer')),
      body: File(path).existsSync()
          ? SfPdfViewer.file(File(path))
          : Center(
              child: Text(
                'File not found:\n$path',
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
