import 'package:flutter/material.dart';

class PdfFile {
  final String name;
  final String date;
  final String size;
  final String? path;
  final int? pages;
  final bool isMerge;

  PdfFile({
    required this.name,
    required this.date,
    required this.size,
    this.path,
    this.pages,
    this.isMerge = true,
  });
}

class PdfProvider with ChangeNotifier {
  final List<PdfFile> _selectedFiles = [];
  final List<PdfFile> _history = [
    PdfFile(name: 'Q4_Report_Merged.pdf', date: 'Oct 24', size: '2.4 MB'),
    PdfFile(
      name: 'Contract_Pages_1-3.pdf',
      date: 'Oct 23',
      size: '840 KB',
      isMerge: false,
    ),
    PdfFile(name: 'Invoices_Batch_A.pdf', date: 'Oct 21', size: '5.1 MB'),
  ];

  List<PdfFile> get selectedFiles => _selectedFiles;
  List<PdfFile> get history => _history;

  void addFiles(List<PdfFile> files) {
    _selectedFiles.addAll(files);
    notifyListeners();
  }

  void removeFile(int index) {
    _selectedFiles.removeAt(index);
    notifyListeners();
  }

  void clearFiles() {
    _selectedFiles.clear();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  Future<void> processPdf({bool isSplit = false}) async {
    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));

    final newFile = PdfFile(
      name: isSplit
          ? 'split_result_${DateTime.now().millisecondsSinceEpoch}.pdf'
          : 'merged_${DateTime.now().millisecondsSinceEpoch}.pdf',
      date: 'Now',
      size: '1.2 MB',
      isMerge: !isSplit,
    );

    _history.insert(0, newFile);
    _selectedFiles.clear();
    notifyListeners();
  }
}
