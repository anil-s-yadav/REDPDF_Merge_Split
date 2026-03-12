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
  bool _cancelRequested = false;
  String? _error;

  final PdfService _pdfService = PdfService();
  final FileIndexService _fileIndexService = FileIndexService();

  static const _prefsHistoryKey = 'pdf_history_v1';
  static const _prefsSystemKey = 'pdf_system_files_v1';

  List<PdfFile> get selectedFiles => List.unmodifiable(_selectedFiles);
  List<PdfFile> get history => List.unmodifiable(_history);
  List<PdfFile> get systemFiles => List.unmodifiable(_systemFiles);

  PdfJobResult? get lastResult => _lastResult;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  Future<void> _init() async {
    await _loadPersisted();
    notifyListeners();
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final historyRaw = prefs.getString(_prefsHistoryKey);
    final systemRaw = prefs.getString(_prefsSystemKey);

    _history
      ..clear()
      ..addAll(historyRaw == null ? const [] : PdfJobResult.decodeFileList(historyRaw));
    _systemFiles
      ..clear()
      ..addAll(systemRaw == null ? const [] : PdfJobResult.decodeFileList(systemRaw));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsHistoryKey, PdfJobResult.encodeList(_history));
    await prefs.setString(_prefsSystemKey, PdfJobResult.encodeList(_systemFiles));
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

  Future<void> refreshSystemFiles({bool forceRescan = false}) async {
    _error = null;
    notifyListeners();

    if (!forceRescan && _systemFiles.isNotEmpty) return;

    try {
      final found = await _fileIndexService.indexPdfs();
      _systemFiles
        ..clear()
        ..addAll(found);
      await _persist();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteFile(PdfFile file, {bool fromHistory = false, bool fromSystem = false}) async {
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
      _systemFiles.removeWhere((x) => x.path == file.path && x.name == file.name);
    }
    await _persist();
    notifyListeners();
  }

  void requestCancel() {
    _cancelRequested = true;
    notifyListeners();
  }

  Future<PdfJobResult?> mergeSelected({Map<String, String> passwords = const {}}) async {
    _error = null;
    _isProcessing = true;
    _cancelRequested = false;
    notifyListeners();
    try {
      final paths = _selectedFiles.map((e) => e.path).whereType<String>().toList();
      if (paths.length < 2) {
        _error = 'Select at least 2 PDF files.';
        return null;
      }

      final output = await _pdfService.merge(
        inputPaths: paths,
        passwords: passwords,
        isCancelled: () => _cancelRequested,
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
    _cancelRequested = false;
    notifyListeners();
    try {
      final result = await _pdfService.splitByRanges(
        inputPath: inputPath,
        ranges: ranges,
        password: password,
        isCancelled: () => _cancelRequested,
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
}
