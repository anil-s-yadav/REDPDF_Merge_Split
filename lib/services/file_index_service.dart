import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/pdf_models.dart';

class FileIndexService {
  Future<List<PdfFile>> indexPdfs() async {
    final roots = <Directory>[];

    if (Platform.isAndroid) {
      // Focus on common public folders so user sees "all" relevant PDFs.
      const base = '/storage/emulated/0';
      final candidates = [
        Directory('$base/Download'),
        Directory('$base/Documents'),
        Directory('$base/DCIM'),
      ];
      roots.addAll(candidates);
    } else {
      try {
        final docs = await getApplicationDocumentsDirectory();
        roots.add(docs);
      } catch (_) {}

      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) roots.add(downloads);
      }
    }

    // Also include our own RedPdf outputs if present.
    try {
      if (Platform.isAndroid) {
        roots.add(Directory('/storage/emulated/0/Download/RedPdf'));
      } else {
        final home = Platform.isWindows
            ? Platform.environment['USERPROFILE']
            : Platform.environment['HOME'];
        if (home != null) {
          roots.add(Directory(p.join(home, 'Downloads', 'RedPdf')));
        }
      }
    } catch (_) {}

    final seen = <String>{};
    final results = <PdfFile>[];

    for (final root in roots) {
      if (!await root.exists()) continue;
      try {
        await for (final entity in root.list(recursive: true, followLinks: false)) {
          if (entity is! File) continue;
          final ext = p.extension(entity.path).toLowerCase();
          if (ext != '.pdf') continue;
          if (seen.contains(entity.path)) continue;
          seen.add(entity.path);

          final stat = await entity.stat();
          results.add(
            PdfFile(
              name: p.basename(entity.path),
              date: '',
              size: _humanBytes(stat.size),
              path: entity.path,
              isMerge: true,
            ),
          );
        }
      } catch (_) {
        // ignore directories we can't read
      }
    }

    results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return results;
  }

  String _humanBytes(int bytes) {
    const kb = 1024;
    const mb = 1024 * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

class PageRange {
  final int from; // 1-based inclusive
  final int to; // 1-based inclusive

  const PageRange(this.from, this.to);
}

