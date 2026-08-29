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
  bool _fileExists = false;
  late final File _file;

  @override
  void initState() {
    super.initState();
    _file = File(widget.path);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () async {
        final exists = await _file.exists();
        if (mounted) {
          setState(() {
            _fileExists = exists;
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
          : _fileExists
          ? SfPdfViewer.file(
              _file,
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
