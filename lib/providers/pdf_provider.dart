import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pdf_models.dart';
import '../services/file_index_service.dart';
import '../services/pdf_service.dart';

class PdfProvider with ChangeNotifier {
  PdfProvider() {
    _init();
  }

  final List<PdfFile> _selectedFiles = [];
  final List<PdfFile> _history = [];
  final List<PdfFile> _systemFiles = [];

  PdfJobResult? _lastResult;
  bool _isProcessing = false;
  bool _isScanningSystem = false;
  bool _showHiddenFiles = false;
  String? _error;
  String? _processingMessage;
  DateTime _lastNotifyTime = DateTime.fromMillisecondsSinceEpoch(0);

  final PdfService _pdfService = PdfService();
  final FileIndexService _fileIndexService = FileIndexService();

  static const _prefsHistoryKey = 'pdf_history_v1';
  static const _prefsSystemKey = 'pdf_system_files_v1';

  List<PdfFile> get selectedFiles => List.unmodifiable(_selectedFiles);
  List<PdfFile> get history => List.unmodifiable(_history);
  List<PdfFile> get systemFiles => List.unmodifiable(_systemFiles);

  PdfJobResult? get lastResult => _lastResult;
  bool get isProcessing => _isProcessing;
  bool get isScanningSystem => _isScanningSystem;
  bool get showHiddenFiles => _showHiddenFiles;
  String? get error => _error;
  String? get processingMessage => _processingMessage;

  Future<void> _init() async {
    await _loadPersisted();
    notifyListeners();
  }

  void _notifyThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastNotifyTime).inMilliseconds >= 300) {
      _lastNotifyTime = now;
      notifyListeners();
    }
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final historyRaw = prefs.getString(_prefsHistoryKey);
    final systemRaw = prefs.getString(_prefsSystemKey);

    _history
      ..clear()
      ..addAll(
        historyRaw == null ? const [] : PdfJobResult.decodeFileList(historyRaw),
      );
    _systemFiles
      ..clear()
      ..addAll(
        systemRaw == null ? const [] : PdfJobResult.decodeFileList(systemRaw),
      );
    _showHiddenFiles = prefs.getBool('show_hidden_files') ?? false;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsHistoryKey, PdfJobResult.encodeList(_history));
    await prefs.setString(
      _prefsSystemKey,
      PdfJobResult.encodeList(_systemFiles),
    );
    await prefs.setBool('show_hidden_files', _showHiddenFiles);
  }

  void addFiles(List<PdfFile> files) {
    _selectedFiles.addAll(files.where((f) => f.path != null));
    notifyListeners();
  }

  void removeFile(int index) {
    if (index < 0 || index >= _selectedFiles.length) return;
    _selectedFiles.removeAt(index);
    notifyListeners();
  }

  void reorderSelected(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _selectedFiles.length) return;
    if (newIndex < 0 || newIndex > _selectedFiles.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _selectedFiles.removeAt(oldIndex);
    _selectedFiles.insert(newIndex, item);
    notifyListeners();
  }

  void clearFiles() {
    _selectedFiles.clear();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _persist();
    notifyListeners();
  }

  void toggleShowHiddenFiles() {
    _showHiddenFiles = !_showHiddenFiles;
    _persist();
    notifyListeners();
    refreshSystemFiles(forceRescan: true);
  }

  Future<void> refreshSystemFiles({bool forceRescan = false}) async {
    if (_isScanningSystem) return;
    _error = null;

    // If not forced and we already have files, don't scan immediately to avoid UI lag.
    // However, we still want to scan if the user explicitly asks or if it's the first time.
    if (_systemFiles.isNotEmpty && !forceRescan) return;

    _isScanningSystem = true;
    notifyListeners();
    try {
      debugPrint('Refreshing system files... forceRescan: $forceRescan');
      final found = await _fileIndexService.indexPdfs(
        showHidden: _showHiddenFiles,
      );
      _systemFiles.clear();
      _systemFiles.addAll(found);
      await _persist();
    } catch (e) {
      debugPrint('Error refreshing system files: $e');
    } finally {
      _isScanningSystem = false;
      notifyListeners();
    }
  }

  Future<void> deleteFile(
    PdfFile file, {
    bool fromHistory = false,
    bool fromSystem = false,
  }) async {
    final path = file.path;
    if (path != null) {
      try {
        final f = File(path);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {
        // ignore file system failure, still allow removal from list
      }
    }

    if (fromHistory) {
      _history.removeWhere((x) => x.path == file.path && x.name == file.name);
    }
    if (fromSystem) {
      _systemFiles.removeWhere(
        (x) => x.path == file.path && x.name == file.name,
      );
    }
    await _persist();
    notifyListeners();
  }

  void requestCancel() {
    _pdfService.cancel();
    notifyListeners();
  }

  Future<PdfJobResult?> mergeSelected({
    Map<String, String> passwords = const {},
  }) async {
    _error = null;
    _isProcessing = true;
    _processingMessage = 'Starting...';
    notifyListeners();
    try {
      final paths = _selectedFiles
          .map((e) => e.path)
          .whereType<String>()
          .toList();
      if (paths.length < 2) {
        _error = 'Select at least 2 PDF files.';
        return null;
      }

      final output = await _pdfService.merge(
        inputPaths: paths,
        passwords: passwords,
        onProgress: (msg) {
          _processingMessage = msg;
          _notifyThrottled();
        },
      );

      final now = DateFormat('MMM d').format(DateTime.now());
      final size = await _pdfService.humanSize(output);
      final historyItem = PdfFile(
        name: output.split(Platform.pathSeparator).last,
        date: now,
        size: size,
        path: output,
        isMerge: true,
      );

      _history.insert(0, historyItem);
      _lastResult = PdfJobResult(isSplit: false, outputPath: output);
      _selectedFiles.clear();
      await _persist();
      return _lastResult;
    } on PdfPasswordRequired catch (e) {
      _error = 'Password required for ${e.name}';
      rethrow;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<PdfJobResult?> split({
    required String inputPath,
    required List<PageRange> ranges,
    String? password,
  }) async {
    _error = null;
    _isProcessing = true;
    _processingMessage = 'Starting...';
    notifyListeners();
    try {
      final result = await _pdfService.splitByRanges(
        inputPath: inputPath,
        ranges: ranges,
        password: password,
        onProgress: (msg) {
          _processingMessage = msg;
          _notifyThrottled();
        },
      );

      final now = DateFormat('MMM d').format(DateTime.now());
      final size = result.zipPath != null
          ? await _pdfService.humanSize(result.zipPath!)
          : '—';

      _history.insert(
        0,
        PdfFile(
          name: (result.zipPath ?? result.outputPaths.first)
              .split(Platform.pathSeparator)
              .last,
          date: now,
          size: size,
          path: result.zipPath ?? result.outputPaths.first,
          isMerge: false,
        ),
      );

      _lastResult = result;
      await _persist();
      return result;
    } on PdfPasswordRequired catch (e) {
      _error = 'Password required for ${e.name}';
      rethrow;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<PdfJobResult?> extract({
    required String inputPath,
    required List<int> pages,
    String? password,
    String? outputNameSuffix,
  }) async {
    _error = null;
    _isProcessing = true;
    _processingMessage = 'Starting...';
    notifyListeners();
    try {
      final result = await _pdfService.extractPages(
        inputPath: inputPath,
        pages: pages,
        password: password,
        outputNameSuffix: outputNameSuffix,
        onProgress: (msg) {
          _processingMessage = msg;
          _notifyThrottled();
        },
      );

      final now = DateFormat('MMM d').format(DateTime.now());
      final size = await _pdfService.humanSize(result.outputPath!);

      _history.insert(
        0,
        PdfFile(
          name: result.outputPath!.split(Platform.pathSeparator).last,
          date: now,
          size: size,
          path: result.outputPath,
          isMerge: false,
        ),
      );

      _lastResult = result;
      await _persist();
      return result;
    } on PdfPasswordRequired catch (e) {
      _error = 'Password required for ${e.name}';
      rethrow;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<int> getSelectedFilesTotalSize() async {
    int total = 0;
    for (final file in _selectedFiles) {
      if (file.path != null) {
        final f = File(file.path!);
        if (await f.exists()) {
          total += await f.length();
        }
      }
    }
    return total;
  }

  String formatBytes(int bytes) {
    const kb = 1024;
    const mb = 1024 * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}

