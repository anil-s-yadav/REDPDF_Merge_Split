import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../models/pdf_models.dart';

class FileIndexService {
  Future<List<PdfFile>> indexPdfs({bool showHidden = false}) async {
    final seen = <String>{};
    final results = <PdfFile>[];

    if (Platform.isAndroid) {
      debugPrint('Starting optimized PDF scan...');

      final commonFolders = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Download/RedPdf',
      ];

      for (final folder in commonFolders) {
        final dir = Directory(folder);
        if (await dir.exists()) {
          debugPrint('Deep scanning common folder: $folder');
          if (!seen.contains(dir.path)) {
            seen.add(dir.path);
            await _scanDirectory(
              dir,
              seen,
              results,
              recursive: true,
              showHidden: showHidden,
            );
          }
        }
      }

      // Now scan the storage root but ONLY its top-level files + selective recursion
      final root = Directory('/storage/emulated/0');
      if (await root.exists()) {
        debugPrint('Scanning storage root (selective)...');
        final entities = await root.list(recursive: false).toList();
        for (final entity in entities) {
          if (entity is File) {
            final path = entity.path;
            if (p.extension(path).toLowerCase() == '.pdf' &&
                !seen.contains(path)) {
              await _addPdfFile(entity, results, seen);
            }
          } else if (entity is Directory) {
            final name = p.basename(entity.path);
            // Skip huge media folders to avoid hanging
            if (name == 'DCIM' ||
                name == 'Pictures' ||
                name == 'Movies' ||
                name == 'Music') {
              continue;
            }
            if (!showHidden) {
              if (name.startsWith('.') ||
                  name == 'Android' ||
                  name.toLowerCase().contains('trash') ||
                  name.toLowerCase().contains('trashed')) {
                continue;
              }
            } else {
              if (name == 'Android') continue;
            }

            if (!seen.contains(entity.path)) {
              seen.add(entity.path);
              await _scanDirectory(
                entity,
                seen,
                results,
                recursive: true,
                showHidden: showHidden,
              );
            }
          }
        }
      }
    } else {
      final roots = <Directory>[];
      try {
        final docs = await getApplicationDocumentsDirectory();
        roots.add(docs);
      } catch (_) {}

      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) roots.add(downloads);
      }

      try {
        final home = Platform.isWindows
            ? Platform.environment['USERPROFILE']
            : Platform.environment['HOME'];
        if (home != null) {
          roots.add(Directory(p.join(home, 'Downloads', 'RedPdf')));
        }
      } catch (_) {}

      for (final root in roots) {
        if (!await root.exists()) continue;
        await _scanDirectory(root, seen, results, showHidden: showHidden);
      }
    }

    results.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return results;
  }

  Future<void> _addPdfFile(
    File file,
    List<PdfFile> results,
    Set<String> seen, {
    bool showHidden = false,
  }) async {
    try {
      final path = file.path;
      final name = p.basename(path);

      if (!showHidden) {
        if (name.startsWith('.') ||
            path.toLowerCase().contains('/.trash') ||
            path.toLowerCase().contains('/.trashed')) {
          return;
        }
      }

      seen.add(path);
      final stat = await file.stat();
      final date = DateFormat('MMM d').format(stat.modified);

      results.add(
        PdfFile(
          name: name,
          date: date,
          size: _humanBytes(stat.size),
          path: path,
          isMerge: true,
        ),
      );
      debugPrint('Found PDF: $name');
    } catch (_) {}
  }

  Future<void> _scanDirectory(
    Directory dir,
    Set<String> seen,
    List<PdfFile> results, {
    bool recursive = true,
    bool showHidden = false,
  }) async {
    try {
      // Use lister to get files in this directory
      final entities = await dir
          .list(recursive: false, followLinks: false)
          .toList();

      for (final entity in entities) {
        try {
          if (entity is File) {
            final path = entity.path;
            if (p.extension(path).toLowerCase() == '.pdf' &&
                !seen.contains(path)) {
              await _addPdfFile(entity, results, seen, showHidden: showHidden);
            }
          } else if (entity is Directory && recursive) {
            final path = entity.path;
            final name = p.basename(path);

            if (!showHidden) {
              if (name.startsWith('.') ||
                  name.toLowerCase().contains('trash') ||
                  name.toLowerCase().contains('trashed')) {
                continue;
              }
            }
            if (name == 'data' || name == 'obb' || name == 'Android') continue;

            if (!seen.contains(path)) {
              seen.add(path);
              await _scanDirectory(
                entity,
                seen,
                results,
                recursive: true,
                showHidden: showHidden,
              );
            }
          }
        } catch (e) {
          // Individual file/dir error, skip it
        }
      }
    } catch (e) {
      // Directory listing failed
    }
  }

  String _humanBytes(int bytes) {
    const kb = 1024;
    const mb = 1024 * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}
