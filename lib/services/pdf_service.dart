import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/pdf_models.dart';
import 'file_index_service.dart';
import 'platform_service.dart';

class PdfService {
  Future<String> merge({
    required List<String> inputPaths,
    Map<String, String> passwords = const {},
    bool Function()? isCancelled,
  }) async {
    final outDir = await _ensureOutputDir();
    final outPath = p.join(outDir.path, 'merged_${DateTime.now().millisecondsSinceEpoch}.pdf');

    final merged = PdfDocument();
    try {
      for (final path in inputPaths) {
        if (isCancelled?.call() ?? false) throw const _Cancelled();
        final bytes = await File(path).readAsBytes();
        try {
          final doc = _open(bytes, password: passwords[path]);
          try {
            merged.pages.add().graphics.drawPdfTemplate(
                  doc.pages[0].createTemplate(),
                  const Offset(0, 0),
                );
            // Append remaining pages
            for (var i = 1; i < doc.pages.count; i++) {
              if (isCancelled?.call() ?? false) throw const _Cancelled();
              final page = merged.pages.add();
              page.graphics.drawPdfTemplate(
                doc.pages[i].createTemplate(),
                const Offset(0, 0),
              );
            }
          } finally {
            doc.dispose();
          }
        } on PdfPasswordRequired {
          rethrow;
        } catch (e) {
          final name = p.basename(path);
          if (_looksLikePasswordError(e)) {
            throw PdfPasswordRequired(path: path, name: name);
          }
          rethrow;
        }
      }

      final outBytes = merged.saveSync();
      await File(outPath).writeAsBytes(outBytes, flush: true);
      await PlatformService.scanFiles([outPath]);
      return outPath;
    } finally {
      merged.dispose();
    }
  }

  Future<PdfJobResult> splitByRanges({
    required String inputPath,
    required List<PageRange> ranges,
    String? password,
    bool Function()? isCancelled,
  }) async {
    final outDir = await _ensureOutputDir();
    final bytes = await File(inputPath).readAsBytes();
    final inputName = p.basenameWithoutExtension(inputPath);

    PdfDocument? source;
    try {
      try {
        source = _open(bytes, password: password);
      } catch (e) {
        if (_looksLikePasswordError(e)) {
          throw PdfPasswordRequired(path: inputPath, name: p.basename(inputPath));
        }
        rethrow;
      }

      final maxPage = source.pages.count;
      final normalized = ranges
          .map((r) => PageRange(r.from.clamp(1, maxPage), r.to.clamp(1, maxPage)))
          .where((r) => r.from <= r.to)
          .toList();

      if (normalized.isEmpty) {
        throw ArgumentError('Please add at least one valid range.');
      }

      final outputs = <String>[];

      for (final range in normalized) {
        if (isCancelled?.call() ?? false) throw const _Cancelled();
        final doc = PdfDocument();
        try {
          for (var pnum = range.from; pnum <= range.to; pnum++) {
            if (isCancelled?.call() ?? false) throw const _Cancelled();
            final page = source.pages[pnum - 1];
            final newPage = doc.pages.add();
            newPage.graphics.drawPdfTemplate(page.createTemplate(), const Offset(0, 0));
          }
          final outPath = p.join(
            outDir.path,
            '${inputName}_${range.from}-${range.to}_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
          await File(outPath).writeAsBytes(doc.saveSync(), flush: true);
          outputs.add(outPath);
        } finally {
          doc.dispose();
        }
      }

      await PlatformService.scanFiles(outputs);

      return PdfJobResult(
        isSplit: true,
        inputPath: inputPath,
        outputPaths: outputs,
        zipPath: null,
        outputPath: outputs.isNotEmpty ? outputs.first : null,
      );
    } finally {
      source?.dispose();
    }
  }

  Future<String> humanSize(String filePath) async {
    final stat = await File(filePath).stat();
    final bytes = stat.size;
    const kb = 1024;
    const mb = 1024 * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  PdfDocument _open(List<int> bytes, {String? password}) {
    // Syncfusion supports password via PdfDocument(inputBytes:..., password:...)
    // but older versions may throw if not supported. We'll try both patterns.
    try {
      return PdfDocument(inputBytes: bytes, password: password);
    } catch (_) {
      return PdfDocument(inputBytes: bytes);
    }
  }

  bool _looksLikePasswordError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('password') || s.contains('encrypted') || s.contains('invalid password');
  }

  Future<Directory> _ensureOutputDir() async {
    if (Platform.isAndroid) {
      // Typical public Downloads path
      final dir = Directory('/storage/emulated/0/Download/RedPdf');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    // Fallback for other platforms: create folder in user's documents/downloads.
    final home = Platform.isWindows
        ? Platform.environment['USERPROFILE']
        : Platform.environment['HOME'];
    final base = home != null ? Directory(home) : Directory.current;
    final downloads = Directory(p.join(base.path, 'Downloads', 'RedPdf'));
    if (!await downloads.exists()) {
      await downloads.create(recursive: true);
    }
    return downloads;
  }
}

class _Cancelled implements Exception {
  const _Cancelled();
}

