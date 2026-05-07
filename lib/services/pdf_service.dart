import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/pdf_models.dart';
import 'platform_service.dart';

class PdfService {
  void cancel() {
    try {
      PdfManipulator().cancelManipulations();
    } catch (_) {}
  }

  Future<String> merge({
    required List<String> inputPaths,
    Map<String, String> passwords = const {},
    void Function(String)? onProgress,
    String? customFileName,
  }) async {
    final outDir = await _ensureOutputDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = (customFileName != null && customFileName.isNotEmpty)
        ? (customFileName.toLowerCase().endsWith('.pdf') ? customFileName : '$customFileName.pdf')
        : 'RedPdf_merge_$timestamp.pdf';

    onProgress?.call("Preparing files...");

    List<String> finalInputPaths = [];
    for (var i = 0; i < inputPaths.length; i++) {
      final path = inputPaths[i];
      if (passwords.containsKey(path) && passwords[path]!.isNotEmpty) {
        onProgress?.call("Decrypting file ${i + 1}...");
        final decryptedPath = await PdfManipulator().pdfDecryption(
          params: PDFDecryptionParams(
            pdfPath: path,
            password: passwords[path]!,
          ),
        );
        if (decryptedPath != null) {
          finalInputPaths.add(decryptedPath);
        } else {
          finalInputPaths.add(path);
        }
      } else {
        finalInputPaths.add(path);
      }
    }

    onProgress?.call("Merging PDFs...");
    final String? tempMergedPath = await PdfManipulator().mergePDFs(
      params: PDFMergerParams(pdfsPaths: finalInputPaths),
    );

    if (tempMergedPath == null) {
      throw CancellationException();
    }

    onProgress?.call("Saving merged PDF...");
    final finalOutPath = await _safeCopy(tempMergedPath, outDir, fileName);
    await PlatformService.scanFiles([finalOutPath]);
    return finalOutPath;
  }

  Future<PdfJobResult> splitByRanges({
    required String inputPath,
    required List<PageRange> ranges,
    String? password,
    void Function(String)? onProgress,
    String? customFileName,
  }) async {
    final outDir = await _ensureOutputDir();
    String inputName = p.basenameWithoutExtension(inputPath);
    if (inputName.length > 50) inputName = inputName.substring(0, 50);

    onProgress?.call('Starting split...');

    String processPath = inputPath;
    if (password != null && password.isNotEmpty) {
      onProgress?.call('Decrypting PDF...');
      final decryptedPath = await PdfManipulator().pdfDecryption(
        params: PDFDecryptionParams(pdfPath: inputPath, password: password),
      );
      if (decryptedPath != null) {
        processPath = decryptedPath;
      }
    }

    onProgress?.call('Reading PDF metadata...');
    final maxPage = await _getPdfPageCount(processPath, password);
    final normalized = ranges
        .map((r) => PageRange(r.from.clamp(1, maxPage), r.to.clamp(1, maxPage)))
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

    List<String> pageRangesParams = uniqueRanges
        .map((r) => "${r.from}-${r.to}")
        .toList();

    onProgress?.call('Splitting PDF into ${uniqueRanges.length} parts...');
    final List<String>? tempPaths = await PdfManipulator().splitPDF(
      params: PDFSplitterParams(
        pdfPath: processPath,
        pageRanges: pageRangesParams,
      ),
    );

    if (tempPaths == null || tempPaths.isEmpty) {
      throw CancellationException();
    }

    onProgress?.call('Saving split PDFs...');
    List<String> outputs = [];
    for (int i = 0; i < tempPaths.length; i++) {
      final range = uniqueRanges[i];
      final isSinglePage = range.from == range.to;
      final int pagesInThisRange = range.to - range.from + 1;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueSuffix = uniqueRanges.length > 1 ? '_${i + 1}' : '';
      final baseName = (customFileName != null && customFileName.isNotEmpty)
          ? customFileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
          : 'RedPdf_split_$timestamp';
      final fileName = '$baseName$uniqueSuffix.pdf';

      final finalOutPath = await _safeCopy(tempPaths[i], outDir, fileName);
      outputs.add(finalOutPath);
    }

    final jobResult = PdfJobResult(
      isSplit: true,
      inputPath: inputPath,
      outputPaths: outputs,
      zipPath: null,
      outputPath: outputs.isNotEmpty ? outputs.first : null,
    );
    await PlatformService.scanFiles(jobResult.outputPaths);
    return jobResult;
  }

  Future<PdfJobResult> extractPages({
    required String inputPath,
    required List<int> pages,
    String? password,
    String? outputNameSuffix,
    void Function(String)? onProgress,
    String? customFileName,
  }) async {
    final outDir = await _ensureOutputDir();
    String inputName = p.basenameWithoutExtension(inputPath);
    if (inputName.length > 50) inputName = inputName.substring(0, 50);

    onProgress?.call('Starting extraction...');

    String processPath = inputPath;
    if (password != null && password.isNotEmpty) {
      onProgress?.call('Decrypting PDF...');
      final decryptedPath = await PdfManipulator().pdfDecryption(
        params: PDFDecryptionParams(pdfPath: inputPath, password: password),
      );
      if (decryptedPath != null) {
        processPath = decryptedPath;
      }
    }

    onProgress?.call('Reading PDF metadata...');
    final count = await _getPdfPageCount(processPath, null);

    // Filter to valid page numbers while preserving the caller-supplied order
    final orderedPages = pages
        .where((pnum) => pnum >= 1 && pnum <= count)
        .toList();

    if (orderedPages.isEmpty) {
      throw ArgumentError('No valid pages specified for extraction.');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    String fileName;
    if (customFileName != null && customFileName.isNotEmpty) {
      fileName = customFileName.toLowerCase().endsWith('.pdf') ? customFileName : '$customFileName.pdf';
    } else {
      final suffixPart = outputNameSuffix != null ? '_$outputNameSuffix' : '';
      fileName = 'RedPdf_extract_$timestamp$suffixPart.pdf';
    }
    
    String outPath = p.join(outDir.path, fileName);

    // Check whether the order matches the natural sorted order.
    final sortedUnique = orderedPages.toSet().toList()..sort();
    final isSortedNoDups =
        orderedPages.length == sortedUnique.length &&
        List.generate(
          orderedPages.length,
          (i) => orderedPages[i] == sortedUnique[i],
        ).every((v) => v);

    if (isSortedNoDups) {
      // Fast path: use native pdfPageDeleter (preserves original order)
      List<int> pagesToDelete = [];
      for (int i = 1; i <= count; i++) {
        if (!sortedUnique.contains(i)) {
          pagesToDelete.add(i);
        }
      }

      String finalPathOutput;
      if (pagesToDelete.isEmpty) {
        finalPathOutput = processPath;
      } else {
        onProgress?.call('Extracting pages natively...');
        final tempPath = await PdfManipulator().pdfPageDeleter(
          params: PDFPageDeleterParams(
            pdfPath: processPath,
            pageNumbers: pagesToDelete,
          ),
        );
        if (tempPath == null) throw CancellationException();
        finalPathOutput = tempPath;
      }

      onProgress?.call('Saving extracted PDF...');
      outPath = await _safeCopy(finalPathOutput, outDir, fileName);
    } else {
      // Ordered / rearranged path: build output PDF page-by-page using Syncfusion
      onProgress?.call('Rearranging pages...');
      final srcBytes = await File(processPath).readAsBytes();
      final srcDoc = PdfDocument(inputBytes: srcBytes);
      // New PdfDocument starts with one blank default page — we remove it
      // by building via PdfPageSettings when adding each page.
      final outDoc = PdfDocument();
      // Remove the default blank page that PdfDocument creates
      bool firstPage = true;

      for (int i = 0; i < orderedPages.length; i++) {
        final pageIdx = orderedPages[i] - 1; // 0-based
        if (pageIdx < 0 || pageIdx >= srcDoc.pages.count) continue;
        onProgress?.call('Copying page ${i + 1} of ${orderedPages.length}...');
        final srcPage = srcDoc.pages[pageIdx];
        final pageSize = srcPage.size;
        // Add a page with matching size
        final PdfPage destPage;
        if (firstPage) {
          firstPage = false;
          // Use the first page (default blank) and set page settings
          outDoc.pageSettings.size = pageSize;
          outDoc.pageSettings.margins.all = 0;
          destPage = outDoc.pages.add();
          // Remove the auto-created blank page (index 0) — actually
          // PdfDocument doesn't add a blank page until we call add().
          // So just use destPage directly.
        } else {
          outDoc.pageSettings.size = pageSize;
          destPage = outDoc.pages.add();
        }
        // Copy graphics/content via template
        final template = srcPage.createTemplate();
        destPage.graphics.drawPdfTemplate(template, Offset.zero);
      }

      onProgress?.call('Saving reordered PDF...');
      final outBytes = await outDoc.save();
      outDoc.dispose();
      srcDoc.dispose();
      try {
        await File(outPath).writeAsBytes(outBytes);
      } catch (e) {
        if (Platform.isAndroid) {
          final appDir = await getApplicationDocumentsDirectory();
          outPath = p.join(appDir.path, fileName);
          await File(outPath).writeAsBytes(outBytes);
        } else {
          rethrow;
        }
      }
    }

    await PlatformService.scanFiles([outPath]);

    return PdfJobResult(
      isSplit: true,
      inputPath: inputPath,
      outputPaths: [outPath],
      outputPath: outPath,
    );
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

  Future<int> _getPdfPageCount(String path, String? password) async {
    try {
      final bytes = await File(path).readAsBytes();
      final doc = _openStatic(bytes, password: password);
      final count = doc.pages.count;
      doc.dispose();
      return count;
    } catch (e) {
      if (_looksLikePasswordErrorStatic(e)) {
        throw PdfPasswordRequired(path: path, name: p.basename(path));
      }
      rethrow;
    }
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
      try {
        final downloadDir = Directory('/storage/emulated/0/Download/RedPdf');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      } catch (_) {}

      // Use app-specific external directory which doesn't require storage permissions
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final outDir = Directory(p.join(extDir.path, 'RedPdf'));
          if (!await outDir.exists()) {
            await outDir.create(recursive: true);
          }
          return outDir;
        }
      } catch (_) {}
      
      // Fallback to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fallbackDir = Directory(p.join(appDir.path, 'RedPdf'));
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      return fallbackDir;
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

  Future<String> _safeCopy(String tempPath, Directory outDir, String fileName) async {
    String outPath = p.join(outDir.path, fileName);
    try {
      await File(tempPath).copy(outPath);
      return outPath;
    } catch (e) {
      if (Platform.isAndroid) {
        // Fallback to application documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final fallbackPath = p.join(appDir.path, fileName);
        try {
          await File(tempPath).copy(fallbackPath);
          return fallbackPath;
        } catch (_) {
          // If copy still fails, try reading and writing bytes directly
          final bytes = await File(tempPath).readAsBytes();
          await File(fallbackPath).writeAsBytes(bytes);
          return fallbackPath;
        }
      }
      rethrow;
    }
  }
}

class CancellationException implements Exception {
  @override
  String toString() => 'Processing was cancelled';
}
