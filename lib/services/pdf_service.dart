import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/pdf_models.dart';
import 'platform_service.dart';

class PdfService {
  Isolate? _currentIsolate;
  ReceivePort? _currentPort;

  void cancel() {
    _currentIsolate?.kill(priority: Isolate.immediate);
    _currentIsolate = null;
    _currentPort?.close();
    _currentPort = null;
  }

  Future<String> merge({
    required List<String> inputPaths,
    Map<String, String> passwords = const {},
    void Function(String)? onProgress,
  }) async {
    final outDir = await _ensureOutputDir();
    final outPath = p.join(
      outDir.path,
      'merged_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    final receivePort = ReceivePort();
    _currentPort = receivePort;
    _currentIsolate = await Isolate.spawn(
      _doMergeWorker,
      _WorkerParams(
        _MergeParams(
          inputPaths: inputPaths,
          passwords: passwords,
          outPath: outPath,
        ),
        receivePort.sendPort,
      ),
    );

    try {
      dynamic finalResult;
      await for (final msg in receivePort) {
        if (msg is String) {
          onProgress?.call(msg);
        } else {
          finalResult = msg;
          break;
        }
      }

      if (finalResult is Exception) throw finalResult;
      await PlatformService.scanFiles([outPath]);
      return outPath;
    } on StateError {
      throw CancellationException();
    } finally {
      receivePort.close();
      _currentIsolate = null;
      _currentPort = null;
    }
  }

  static void _doMergeWorker(_WorkerParams params) async {
    try {
      await _doMerge(params.data as _MergeParams, params.sendPort);
      params.sendPort.send(null);
    } catch (e) {
      params.sendPort.send(e);
    }
  }

  static Future<void> _doMerge(_MergeParams params, SendPort sendPort) async {
    final merged = PdfDocument();

    try {
      int processedFiles = 0;
      final totalFiles = params.inputPaths.length;

      for (final path in params.inputPaths) {
        processedFiles++;

        if (processedFiles % 2 == 0) {
          sendPort.send("Merging $processedFiles of $totalFiles");
        }

        final bytes = await File(path).readAsBytes();
        final doc = _openStatic(bytes, password: params.passwords[path]);

        try {
          final count = doc.pages.count;

          for (int i = 0; i < count; i++) {
            final page = doc.pages[i];

            final newPage = merged.pages.add();

            newPage.graphics.drawPdfTemplate(
              page.createTemplate(),
              Offset.zero,
              Size(page.size.width, page.size.height),
            );
          }
        } finally {
          doc.dispose();
        }
      }

      sendPort.send("Saving merged PDF...");

      final outBytes = merged.saveSync();
      await File(params.outPath).writeAsBytes(outBytes);
    } finally {
      merged.dispose();
    }
  }

  Future<PdfJobResult> splitByRanges({
    required String inputPath,
    required List<PageRange> ranges,
    String? password,
    void Function(String)? onProgress,
  }) async {
    final outDir = await _ensureOutputDir();
    final inputName = p.basenameWithoutExtension(inputPath);

    final receivePort = ReceivePort();
    _currentPort = receivePort;
    _currentIsolate = await Isolate.spawn(
      _doSplitWorker,
      _WorkerParams(
        _SplitParams(
          inputPath: inputPath,
          ranges: ranges,
          password: password,
          outDirPath: outDir.path,
          inputName: inputName,
        ),
        receivePort.sendPort,
      ),
    );

    try {
      dynamic finalResult;
      await for (final msg in receivePort) {
        if (msg is String) {
          onProgress?.call(msg);
        } else {
          finalResult = msg;
          break;
        }
      }

      if (finalResult is Exception) throw finalResult;
      final jobResult = finalResult as PdfJobResult;
      await PlatformService.scanFiles(jobResult.outputPaths);
      return jobResult;
    } on StateError {
      throw CancellationException();
    } finally {
      receivePort.close();
      _currentIsolate = null;
      _currentPort = null;
    }
  }

  static void _doSplitWorker(_WorkerParams params) async {
    try {
      final res = await _doSplit(params.data as _SplitParams, params.sendPort);
      params.sendPort.send(res);
    } catch (e) {
      params.sendPort.send(e);
    }
  }

  static Future<PdfJobResult> _doSplit(
    _SplitParams params,
    SendPort sendPort,
  ) async {
    sendPort.send('Reading source PDF...');
    final bytes = await File(params.inputPath).readAsBytes();
    PdfDocument? source;
    try {
      try {
        source = _openStatic(bytes, password: params.password);
      } catch (e) {
        if (_looksLikePasswordErrorStatic(e)) {
          throw PdfPasswordRequired(
            path: params.inputPath,
            name: p.basename(params.inputPath),
          );
        }
        rethrow;
      }

      final maxPage = source.pages.count;
      final normalized = params.ranges
          .map(
            (r) => PageRange(r.from.clamp(1, maxPage), r.to.clamp(1, maxPage)),
          )
          .where((r) => r.from <= r.to)
          .toSet()
          .toList();

      if (normalized.isEmpty) {
        throw ArgumentError('Please add at least one valid range.');
      }

      final uniqueRanges = <PageRange>[];
      final seen = <String>{};
      for (final r in normalized) {
        final key = '${r.from}-${r.to}';
        if (!seen.contains(key)) {
          uniqueRanges.add(r);
          seen.add(key);
        }
      }

      final outputs = <String>[];

      int rangeIdx = 0;
      for (final range in uniqueRanges) {
        rangeIdx++;
        if (rangeIdx % 2 == 0) {
          sendPort.send(
            'Processing range $rangeIdx of ${uniqueRanges.length}...',
          );
        }
        final doc = PdfDocument();
        doc.pageSettings.margins.all = 0;
        try {
          for (var pnum = range.from; pnum <= range.to; pnum++) {
            final page = source.pages[pnum - 1];
            doc.pageSettings.size = page.size;
            final newPage = doc.pages.add();
            // Ensure no margins for the drew template
            newPage.graphics.drawPdfTemplate(
              page.createTemplate(),
              const Offset(0, 0),
            );
          }
          final String rangeStr = range.from == range.to
              ? 'page_${range.from}'
              : 'pages_${range.from}-${range.to}';
          final outPath = p.join(
            params.outDirPath,
            '${params.inputName}_$rangeStr.pdf',
          );
          await File(outPath).writeAsBytes(doc.saveSync());
          outputs.add(outPath);
        } finally {
          doc.dispose();
        }
      }

      return PdfJobResult(
        isSplit: true,
        inputPath: params.inputPath,
        outputPaths: outputs,
        zipPath: null,
        outputPath: outputs.isNotEmpty ? outputs.first : null,
      );
    } finally {
      source?.dispose();
    }
  }

  Future<PdfJobResult> extractPages({
    required String inputPath,
    required List<int> pages,
    String? password,
    String? outputNameSuffix,
    void Function(String)? onProgress,
  }) async {
    final outDir = await _ensureOutputDir();
    final inputName = p.basenameWithoutExtension(inputPath);

    final receivePort = ReceivePort();
    _currentPort = receivePort;
    _currentIsolate = await Isolate.spawn(
      _doExtractWorker,
      _WorkerParams(
        _ExtractParams(
          inputPath: inputPath,
          pages: pages,
          password: password,
          outDirPath: outDir.path,
          inputName: inputName,
          suffix: outputNameSuffix,
        ),
        receivePort.sendPort,
      ),
    );

    try {
      dynamic finalResult;
      await for (final msg in receivePort) {
        if (msg is String) {
          onProgress?.call(msg);
        } else {
          finalResult = msg;
          break;
        }
      }

      if (finalResult is Exception) throw finalResult;
      final jobResult = finalResult as PdfJobResult;
      await PlatformService.scanFiles([jobResult.outputPath!]);
      return jobResult;
    } on StateError {
      throw CancellationException();
    } finally {
      receivePort.close();
      _currentIsolate = null;
      _currentPort = null;
    }
  }

  static void _doExtractWorker(_WorkerParams params) async {
    try {
      final res = await _doExtract(
        params.data as _ExtractParams,
        params.sendPort,
      );
      params.sendPort.send(res);
    } catch (e) {
      params.sendPort.send(e);
    }
  }

  static Future<PdfJobResult> _doExtract(
    _ExtractParams params,
    SendPort sendPort,
  ) async {
    sendPort.send('Reading source PDF...');
    final bytes = await File(params.inputPath).readAsBytes();
    PdfDocument? source;
    PdfDocument? dest;
    try {
      try {
        source = _openStatic(bytes, password: params.password);
      } catch (e) {
        if (_looksLikePasswordErrorStatic(e)) {
          throw PdfPasswordRequired(
            path: params.inputPath,
            name: p.basename(params.inputPath),
          );
        }
        rethrow;
      }

      final maxPage = source.pages.count;
      final uniquePages =
          params.pages
              .where((pnum) => pnum >= 1 && pnum <= maxPage)
              .toSet()
              .toList()
            ..sort();

      if (uniquePages.isEmpty) {
        throw ArgumentError('No valid pages specified for extraction.');
      }

      dest = PdfDocument();
      dest.pageSettings.margins.all = 0;

      sendPort.send('Extracting ${uniquePages.length} pages...');
      int extractedPages = 0;
      for (final pnum in uniquePages) {
        extractedPages++;
        if (extractedPages % 2 == 0) {
          sendPort.send(
            'Extracting page $extractedPages of ${uniquePages.length}...',
          );
        }
        final page = source.pages[pnum - 1];
        dest.pageSettings.size = page.size;
        final newPage = dest.pages.add();
        newPage.graphics.drawPdfTemplate(
          page.createTemplate(),
          const Offset(0, 0),
        );
      }

      final suffix = params.suffix ?? 'extracted';
      final outPath = p.join(
        params.outDirPath,
        '${params.inputName}_$suffix.pdf',
      );

      await File(outPath).writeAsBytes(dest.saveSync());

      return PdfJobResult(
        isSplit: true,
        inputPath: params.inputPath,
        outputPaths: [outPath],
        outputPath: outPath,
      );
    } finally {
      source?.dispose();
      dest?.dispose();
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

  static PdfDocument _openStatic(List<int> bytes, {String? password}) {
    try {
      return PdfDocument(inputBytes: bytes, password: password);
    } catch (_) {
      return PdfDocument(inputBytes: bytes);
    }
  }

  static bool _looksLikePasswordErrorStatic(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('password') ||
        s.contains('encrypted') ||
        s.contains('invalid password');
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

class _WorkerParams {
  final dynamic data;
  final SendPort sendPort;
  _WorkerParams(this.data, this.sendPort);
}

class _MergeParams {
  final List<String> inputPaths;
  final Map<String, String> passwords;
  final String outPath;
  _MergeParams({
    required this.inputPaths,
    required this.passwords,
    required this.outPath,
  });
}

class _SplitParams {
  final String inputPath;
  final List<PageRange> ranges;
  final String? password;
  final String outDirPath;
  final String inputName;
  _SplitParams({
    required this.inputPath,
    required this.ranges,
    this.password,
    required this.outDirPath,
    required this.inputName,
  });
}

class _ExtractParams {
  final String inputPath;
  final List<int> pages;
  final String? password;
  final String outDirPath;
  final String inputName;
  final String? suffix;
  _ExtractParams({
    required this.inputPath,
    required this.pages,
    this.password,
    required this.outDirPath,
    required this.inputName,
    this.suffix,
  });
}

class CancellationException implements Exception {
  @override
  String toString() => 'Processing was cancelled';
}
