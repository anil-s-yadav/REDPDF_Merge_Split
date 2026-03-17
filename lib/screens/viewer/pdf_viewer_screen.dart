import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String path;
  final String? title;

  const PdfViewerScreen({super.key, required this.path, this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isReady = true;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'PDF Viewer')),
      body: !_isReady
          ? const Center(child: CircularProgressIndicator())
          : File(widget.path).existsSync()
          ? SfPdfViewer.file(
              File(widget.path),
              canShowScrollHead: false,
              canShowScrollStatus: false,
            )
          : Center(
              child: Text(
                'File not found:\n${widget.path}',
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
