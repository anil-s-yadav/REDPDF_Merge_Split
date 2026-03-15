import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
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
  }) async {
    final outDir = await _ensureOutputDir();
    final name1 = p.basenameWithoutExtension(inputPaths[0]);
    final name2 = inputPaths.length > 1
        ? p.basenameWithoutExtension(inputPaths[1])
        : '';
    final outPath = p.join(
      outDir.path,
      'merged_${name1}${name2.isNotEmpty ? '_$name2' : ''}.pdf',
    );

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
    await File(tempMergedPath).copy(outPath);
    await PlatformService.scanFiles([outPath]);
    return outPath;
  }

  Future<PdfJobResult> splitByRanges({
    required String inputPath,
    required List<PageRange> ranges,
    String? password,
    void Function(String)? onProgress,
  }) async {
    final outDir = await _ensureOutputDir();
    final inputName = p.basenameWithoutExtension(inputPath);

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
      
      String outPath;
      if (isSinglePage) {
        outPath = p.join(outDir.path, '${inputName}_page_${range.from}.pdf');
      } else {
        // Fallback suffix if there's conflict
        final uniqueSuffix = uniqueRanges.length > 1 ? '_part_${i + 1}' : '';
        outPath = p.join(
          outDir.path, 
          'Split_${pagesInThisRange}_pages_$inputName$uniqueSuffix.pdf'
        );
      }

      await File(tempPaths[i]).copy(outPath);
      outputs.add(outPath);
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
  }) async {
    final outDir = await _ensureOutputDir();
    final inputName = p.basenameWithoutExtension(inputPath);

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
    final orderedPages =
        pages.where((pnum) => pnum >= 1 && pnum <= count).toList();

    if (orderedPages.isEmpty) {
      throw ArgumentError('No valid pages specified for extraction.');
    }

    final outPath = outputNameSuffix != null
        ? p.join(outDir.path, '${inputName}_$outputNameSuffix.pdf')
        : p.join(outDir.path, 'Split_${orderedPages.length}_pages_$inputName.pdf');

    // Check whether the order matches the natural sorted order.
    final sortedUnique = orderedPages.toSet().toList()..sort();
    final isSortedNoDups =
        orderedPages.length == sortedUnique.length &&
        List.generate(orderedPages.length, (i) => orderedPages[i] == sortedUnique[i])
            .every((v) => v);

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
      await File(finalPathOutput).copy(outPath);
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
        destPage.graphics.drawPdfTemplate(
          template,
          Offset.zero,
        );
      }

      onProgress?.call('Saving reordered PDF...');
      final outBytes = await outDoc.save();
      outDoc.dispose();
      srcDoc.dispose();
      await File(outPath).writeAsBytes(outBytes);
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

class CancellationException implements Exception {
  @override
  String toString() => 'Processing was cancelled';
}
