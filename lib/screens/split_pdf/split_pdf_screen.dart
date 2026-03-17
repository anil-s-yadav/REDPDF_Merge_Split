import 'dart:io';

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

import '../../core/theme/pdf_theme_extension.dart';
import '../../models/pdf_models.dart';
import '../../providers/pdf_provider.dart';
import '../viewer/pdf_viewer_screen.dart';
import '../processing/processing_screen.dart';

enum _SplitMode { extract, everyPage, range, delete }

class SplitPdfScreen extends StatefulWidget {
  final String? initialPath;

  const SplitPdfScreen({super.key, this.initialPath});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  String? _inputPath;
  String? _inputName;
  int? _pageCount;
  String? _pdfPassword; // remembered password for locked PDFs

  pdfx.PdfDocument? _pdfDocument;
  final Map<int, Uint8List> _thumbnails = {};
  bool _isLoadingThumbnails = false;

  _SplitMode _mode = _SplitMode.extract;

  // --- range mode ---
  final List<_RangeRow> _ranges = [
    _RangeRow(
      from: TextEditingController(text: '1'),
      to: TextEditingController(text: '1'),
    ),
  ];

  // --- extract mode ---
  final TextEditingController _extractController = TextEditingController(
    text: '1,2,3',
  );
  // Pages in user-defined order for the output PDF
  List<int> _extractOrderedPages = [];
  // Which pages are visually selected on the grid
  final Set<int> _extractSelected = {};

  // --- delete mode ---
  final TextEditingController _deleteController = TextEditingController(
    text: '1',
  );
  final Set<int> _deleteSelected = {};

  @override
  void initState() {
    super.initState();
    _extractController.addListener(_onExtractTextChanged);
    _deleteController.addListener(_onDeleteTextChanged);
  }

  @override
  void dispose() {
    for (final r in _ranges) {
      r.from.dispose();
      r.to.dispose();
    }
    _extractController.removeListener(_onExtractTextChanged);
    _extractController.dispose();
    _deleteController.removeListener(_onDeleteTextChanged);
    _deleteController.dispose();
    _pdfDocument?.close();
    super.dispose();
  }

  // ─── pick PDF ───────────────────────────────────────────────────────────────
  Future<void> _pickPdf() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (res == null || res.files.isEmpty) return;
    final p = res.files.single.path;
    if (p == null) return;
    setState(() {
      _inputPath = p;
      _inputName = res.files.single.name;
      _pageCount = null;
      _pdfPassword = null;
      _extractOrderedPages = [];
      _extractSelected.clear();
      _deleteSelected.clear();
      _pdfDocument?.close();
      _pdfDocument = null;
      _thumbnails.clear();
      _isLoadingThumbnails = false;
    });
    await _loadPageCount();
  }

  // ─── load page count ────────────────────────────────────────────────────────
  Future<void> _loadPageCount({String? password}) async {
    final path = _inputPath;
    if (path == null) return;
    try {
      final bytes = await File(path).readAsBytes();
      final doc = password == null
          ? PdfDocument(inputBytes: bytes)
          : PdfDocument(inputBytes: bytes, password: password);
      final count = doc.pages.count;
      doc.dispose();
      
      try {
        _pdfDocument?.close();
        _pdfDocument = password == null 
            ? await pdfx.PdfDocument.openFile(path)
            : await pdfx.PdfDocument.openFile(path, password: password);
      } catch (_) {
        // ignore pdfx errors, we still have _pageCount
      }

      if (!mounted) return;
      setState(() {
        _pageCount = count;
        if (password != null) _pdfPassword = password;
      });
      _generateThumbnails();
      // Sync text fields with valid ranges
      _onExtractTextChanged();
      _onDeleteTextChanged();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().toLowerCase();
      final looksLocked =
          message.contains('password') || message.contains('encrypted');
      if (looksLocked && password == null) {
        final controller = TextEditingController();
        final pwd = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Password Required'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This PDF is locked. Enter the password to open it.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'PDF Password',
                    prefixIcon: Icon(Icons.key_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => Navigator.pop(ctx, v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, controller.text),
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('Unlock'),
              ),
            ],
          ),
        );
        if (pwd != null && pwd.isNotEmpty && mounted) {
          await _loadPageCount(password: pwd);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read PDF: $e')),
        );
      }
    }
  }

  // ─── text ↔ selection sync ──────────────────────────────────────────────────
  void _onExtractTextChanged() {
    final pages = _parsePageList(_extractController.text);
    setState(() {
      _extractSelected
        ..clear()
        ..addAll(pages);
      // Retain existing order, append newly added, remove dropped
      _extractOrderedPages.retainWhere((p) => _extractSelected.contains(p));
      for (final p in pages) {
        if (!_extractOrderedPages.contains(p)) _extractOrderedPages.add(p);
      }
    });
  }

  void _onDeleteTextChanged() {
    final pages = _parsePageList(_deleteController.text);
    setState(() {
      _deleteSelected
        ..clear()
        ..addAll(pages);
    });
  }

  List<int> _parsePageList(String raw) {
    final nums = <int>[];
    for (final part in raw.split(RegExp(r'[,\s]+'))) {
      if (part.contains('-')) {
        final sub = part.split('-');
        final from = int.tryParse(sub.first.trim());
        final to = int.tryParse(sub.last.trim());
        if (from != null && to != null) {
          for (var x = from; x <= to; x++) { nums.add(x); }
        }
      } else {
        final n = int.tryParse(part.trim());
        if (n != null) nums.add(n);
      }
    }
    if (_pageCount != null) nums.removeWhere((n) => n < 1 || n > _pageCount!);
    return nums.toSet().toList()..sort();
  }

  String _listToText(Iterable<int> pages) =>
      (pages.toList()..sort()).join(',');

  // ─── toggle grid taps ──────────────────────────────────────────────────────
  void _toggleExtractPage(int pageNum) {
    setState(() {
      if (_extractSelected.contains(pageNum)) {
        _extractSelected.remove(pageNum);
        _extractOrderedPages.remove(pageNum);
      } else {
        _extractSelected.add(pageNum);
        _extractOrderedPages.add(pageNum);
      }
      _extractController.removeListener(_onExtractTextChanged);
      _extractController.text = _listToText(_extractSelected);
      _extractController.addListener(_onExtractTextChanged);
    });
  }

  void _toggleDeletePage(int pageNum) {
    setState(() {
      if (_deleteSelected.contains(pageNum)) {
        _deleteSelected.remove(pageNum);
      } else {
        _deleteSelected.add(pageNum);
      }
      _deleteController.removeListener(_onDeleteTextChanged);
      _deleteController.text = _listToText(_deleteSelected);
      _deleteController.addListener(_onDeleteTextChanged);
    });
  }

  // ─── run split / extract / delete ─────────────────────────────────────────
  Future<void> _runSplit(PdfProvider provider) async {
    final path = _inputPath;
    if (path == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final fileBytes = await File(path).length();
    final sizeStr = provider.formatBytes(fileBytes);
    final isLarge = fileBytes > 2 * 1024 * 1024;

    // --- DELETE mode ---
    if (_mode == _SplitMode.delete && _pageCount != null) {
      if (_deleteSelected.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Select pages to delete first.')),
        );
        return;
      }
      final surviving = <int>[];
      for (var i = 1; i <= _pageCount!; i++) {
        if (!_deleteSelected.contains(i)) { surviving.add(i); }
      }
      if (surviving.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot delete all pages. At least one must remain.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(
            type: ProcessingJobType.extract,
            estimatedSize: sizeStr,
            isLarge: isLarge,
            inputPath: path,
            pages: surviving,
            password: _pdfPassword,
            suffix: 'deleted_${_deleteSelected.length}_pages',
          ),
        ),
      );
      return;
    }

    // --- EXTRACT mode → single PDF ---
    if (_mode == _SplitMode.extract) {
      final ordered = _extractOrderedPages.isNotEmpty
          ? _extractOrderedPages
          : _parsePageList(_extractController.text);
      if (ordered.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Select at least one page to extract.'),
          ),
        );
        return;
      }
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(
            type: ProcessingJobType.extract,
            estimatedSize: sizeStr,
            isLarge: isLarge,
            inputPath: path,
            pages: ordered,
            password: _pdfPassword,
            suffix: 'extracted',
          ),
        ),
      );
      return;
    }

    // --- RANGE / EVERY-PAGE mode ---
    final effectiveRanges =
        _mode == _SplitMode.everyPage && _pageCount != null
        ? List<PageRange>.generate(
            _pageCount!,
            (i) => PageRange(i + 1, i + 1),
          )
        : _buildRangesForSplit();

    if (effectiveRanges.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter valid page ranges.')),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          type: ProcessingJobType.split,
          estimatedSize: sizeStr,
          isLarge: isLarge,
          inputPath: path,
          ranges: effectiveRanges,
          password: _pdfPassword,
        ),
      ),
    );
  }

  List<PageRange> _buildRangesForSplit() {
    final out = <PageRange>[];
    for (final r in _ranges) {
      final from = int.tryParse(r.from.text.trim());
      final to = int.tryParse(r.to.text.trim());
      if (from == null || to == null) continue;
      out.add(PageRange(from, to));
    }
    return out;
  }

  // ─── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<PdfProvider>();

    final routeArg = ModalRoute.of(context)?.settings.arguments;
    if (_inputPath == null && routeArg is String) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        setState(() {
          _inputPath = routeArg;
          _inputName = routeArg.split(Platform.pathSeparator).last;
        });
        await _loadPageCount();
      });
    }

    final path = _inputPath;
    final canSplit = path != null && !provider.isProcessing;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Split PDF'),
        actions: [
          if (path != null)
            TextButton(
              onPressed: provider.isProcessing
                  ? null
                  : () {
                      setState(() {
                        _inputPath = null;
                        _inputName = null;
                        _pageCount = null;
                        _pdfPassword = null;
                        _extractOrderedPages = [];
                        _extractSelected.clear();
                        _deleteSelected.clear();
                        _pdfDocument?.close();
                        _pdfDocument = null;
                        _thumbnails.clear();
                        _isLoadingThumbnails = false;
                      });
                    },
              child: const Text('Reselect'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectedFileTile(pdfTheme, colorScheme),
            const SizedBox(height: 16),
            if (path != null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerScreen(
                            path: path,
                            title: _inputName ?? 'PDF',
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Preview'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: provider.isProcessing ? null : _pickPdf,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Change'),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: provider.isProcessing ? null : _pickPdf,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Select PDF'),
              ),
            const SizedBox(height: 24),
            _buildTabToggle(pdfTheme, colorScheme),
            const SizedBox(height: 16),

            // ── mode body ──
            if (_mode == _SplitMode.range) ...[
              _buildRangeHeader(pdfTheme, provider.isProcessing),
              const SizedBox(height: 12),
              ..._buildRangeEditors(colorScheme, pdfTheme, provider.isProcessing),
            ] else if (_mode == _SplitMode.extract) ...[
              _buildExtractSection(pdfTheme, colorScheme, provider.isProcessing),
            ] else if (_mode == _SplitMode.delete) ...[
              _buildDeleteSection(pdfTheme, colorScheme, provider.isProcessing),
            ] else if (_mode == _SplitMode.everyPage) ...[
              const Text(
                'Split every page',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _pageCount == null
                    ? 'Each page will become its own PDF.'
                    : '$_pageCount PDFs will be created (one per page).',
                style: const TextStyle(color: Colors.grey),
              ),
            ],

            const SizedBox(height: 10),
            _buildModeDescription(),
            const SizedBox(height: 24),

            if (provider.isProcessing) ...[
              const SizedBox(height: 24),
              const LinearProgressIndicator(),
            ] else ...[
              ElevatedButton(
                onPressed: canSplit ? () => _runSplit(provider) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pdfTheme.splitPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call_split_rounded),
                    SizedBox(width: 12),
                    Text(
                      'Split PDF Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── EXTRACT section ───────────────────────────────────────────────────────
  Widget _buildExtractSection(
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    bool disabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Extract pages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Selected pages will be combined into a single PDF in the order shown below.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _extractController,
          enabled: !disabled,
          decoration: const InputDecoration(
            hintText: 'e.g. 1,3,5 or 2-6',
            labelText: 'Page numbers',
            prefixIcon: Icon(Icons.format_list_numbered),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        if (_pageCount != null && _pageCount! > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_extractSelected.length} of $_pageCount selected',
                style: TextStyle(
                  color: pdfTheme.splitPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              TextButton.icon(
                onPressed: disabled
                    ? null
                    : () {
                        setState(() {
                          _extractSelected.clear();
                          _extractOrderedPages.clear();
                          _extractController.removeListener(
                            _onExtractTextChanged,
                          );
                          _extractController.text = '';
                          _extractController.addListener(_onExtractTextChanged);
                        });
                      },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPageGrid(
            pageCount: _pageCount!,
            selectedPages: _extractSelected,
            onTap: disabled ? null : _toggleExtractPage,
            pdfTheme: pdfTheme,
            colorScheme: colorScheme,
          ),
        ],

        // ── Reorder section ──
        if (_extractOrderedPages.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.reorder, color: pdfTheme.splitPrimary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Output page order',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Drag to rearrange — this is the order pages appear in the extracted PDF.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _buildExtractReorderList(pdfTheme, colorScheme, disabled),
        ],
      ],
    );
  }

  // ─── DELETE section ────────────────────────────────────────────────────────
  Widget _buildDeleteSection(
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    bool disabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delete pages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Marked pages will be removed — a new PDF without them will be saved.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _deleteController,
          enabled: !disabled,
          decoration: const InputDecoration(
            hintText: 'e.g. 1,3,5 or 2-6',
            labelText: 'Pages to delete',
            prefixIcon: Icon(Icons.delete_sweep_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 16),
        if (_pageCount != null && _pageCount! > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_deleteSelected.length} of $_pageCount marked for deletion',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              TextButton.icon(
                onPressed: disabled
                    ? null
                    : () {
                        setState(() {
                          _deleteSelected.clear();
                          _deleteController.removeListener(_onDeleteTextChanged);
                          _deleteController.text = '';
                          _deleteController.addListener(_onDeleteTextChanged);
                        });
                      },
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPageGrid(
            pageCount: _pageCount!,
            selectedPages: _deleteSelected,
            onTap: disabled ? null : _toggleDeletePage,
            pdfTheme: pdfTheme,
            colorScheme: colorScheme,
            selectedColor: Colors.red,
            selectedIcon: Icons.delete_outline,
            selectedLabel: 'DELETE',
          ),
        ],
      ],
    );
  }

  // ─── shared visual page grid ───────────────────────────────────────────────
  Widget _buildPageGrid({
    required int pageCount,
    required Set<int> selectedPages,
    required void Function(int)? onTap,
    required PdfThemeExtension pdfTheme,
    required ColorScheme colorScheme,
    Color? selectedColor,
    IconData? selectedIcon,
    String? selectedLabel,
  }) {
    final selColor = selectedColor ?? pdfTheme.splitPrimary;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: pageCount,
      itemBuilder: (_, i) {
        final pageNum = i + 1;
        final isSelected = selectedPages.contains(pageNum);

        return GestureDetector(
          onTap: onTap == null ? null : () => onTap(pageNum),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? selColor
                    : colorScheme.outline.withValues(alpha: 0.25),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? selColor.withValues(alpha: 0.1)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Simulated page preview area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      fit: StackFit.expand,
                      children: [
                        if (_thumbnails[pageNum] != null)
                          Image.memory(
                            _thumbnails[pageNum]!,
                            fit: BoxFit.cover,
                          )
                        else
                          Center(
                            child: _isLoadingThumbnails
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.article_outlined,
                                    color: Colors.grey[300],
                                    size: 32,
                                  ),
                          ),
                        if (isSelected)
                          Container(
                            color: selColor.withValues(alpha: 0.3),
                            child: Center(
                              child: Icon(
                                selectedIcon ?? Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Page number label
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    'P $pageNum',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? selColor : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── drag-to-reorder extract list ─────────────────────────────────────────
  Widget _buildExtractReorderList(
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    bool disabled,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _extractOrderedPages.length,
      onReorder: disabled
          ? (_, _) {}
          : (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _extractOrderedPages.removeAt(oldIndex);
                _extractOrderedPages.insert(newIndex, item);
              });
            },
      itemBuilder: (context, index) {
        final pageNum = _extractOrderedPages[index];
        return Container(
          key: ValueKey('ord_$pageNum'),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: pdfTheme.splitContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: pdfTheme.splitPrimary.withValues(alpha: 0.25),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: Container(
              width: 36,
              height: 46,
              decoration: BoxDecoration(
                color: pdfTheme.splitPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: pdfTheme.splitPrimary,
                    size: 18,
                  ),
                  Text(
                    '$pageNum',
                    style: TextStyle(
                      fontSize: 10,
                      color: pdfTheme.splitPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            title: Text(
              'Page $pageNum',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: pdfTheme.splitPrimary,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              'Position ${index + 1} in output',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                  tooltip: 'Remove',
                  onPressed: disabled
                      ? null
                      : () {
                          setState(() {
                            _extractOrderedPages.remove(pageNum);
                            _extractSelected.remove(pageNum);
                            _extractController.removeListener(
                              _onExtractTextChanged,
                            );
                            _extractController.text =
                                _listToText(_extractSelected);
                            _extractController.addListener(_onExtractTextChanged);
                          });
                        },
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_indicator, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── file tile ─────────────────────────────────────────────────────────────
  Widget _buildSelectedFileTile(
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
  ) {
    final has = _inputPath != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pdfTheme.splitContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              has ? Icons.picture_as_pdf : Icons.help_center_outlined,
              color: pdfTheme.splitPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  has ? (_inputName ?? 'Selected PDF') : 'No PDF selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      has
                          ? '${_pageCount ?? '—'} Pages'
                          : 'Tap "Select PDF" to begin',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (has && _pdfPassword != null) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.lock_open,
                        size: 13,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        'Unlocked',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── mode tab toggle ───────────────────────────────────────────────────────
  Widget _buildTabToggle(PdfThemeExtension pdfTheme, ColorScheme colorScheme) {
    const tabs = [
      (_SplitMode.range, 'By Range'),
      (_SplitMode.extract, 'Extract'),
      (_SplitMode.everyPage, 'Every Page'),
      (_SplitMode.delete, 'Delete'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: tabs.map((tab) {
          final selected = _mode == tab.$1;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _mode = tab.$1),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tab.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? pdfTheme.splitPrimary : Colors.grey,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _generateThumbnails() async {
    if (_pdfDocument == null || _pageCount == null || _pageCount! <= 0) return;
    setState(() => _isLoadingThumbnails = true);
    for (var i = 1; i <= _pageCount!; i++) {
      if (!mounted) break;
      try {
        final page = await _pdfDocument!.getPage(i);
       
        // We render at a small resolution
        final renderResult = await page.render(
          width: page.width / 4, // Intentionally double
          height: page.height / 4, // Intentionally double
          format: pdfx.PdfPageImageFormat.jpeg,
        );
        
        if (renderResult != null && mounted) {
          setState(() {
            _thumbnails[i] = renderResult.bytes;
          });
        }
        await page.close();
      } catch (_) {
        // ignore individual page render errors
      }
    }
    if (mounted) setState(() => _isLoadingThumbnails = false);
  }

  // ─── parsing helpers ──────────────────────────────────────────────────────────
    // ─── range header ──────────────────────────────────────────────────────────
  Widget _buildRangeHeader(PdfThemeExtension pdfTheme, bool disabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Define Ranges',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: disabled
              ? null
              : () {
                  setState(() {
                    _ranges.add(
                      _RangeRow(
                        from: TextEditingController(text: '1'),
                        to: TextEditingController(text: '1'),
                      ),
                    );
                  });
                },
          icon: Icon(Icons.add_circle, color: pdfTheme.splitPrimary),
          label: Text(
            'Add Range',
            style: TextStyle(
              color: pdfTheme.splitPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ─── mode description ──────────────────────────────────────────────────────
  Widget _buildModeDescription() {
    String subtitle;
    switch (_mode) {
      case _SplitMode.extract:
        subtitle =
            'Creates a single new PDF containing only the pages you selected, in the order you arranged them.';
        break;
      case _SplitMode.everyPage:
        subtitle =
            'Turn each page into its own PDF file — great for invoices, certificates, or individual documents.';
        break;
      case _SplitMode.range:
        subtitle =
            'Choose page ranges like 1–5, 6–10 etc. Each range becomes a separate PDF (chapters, sections).';
        break;
      case _SplitMode.delete:
        subtitle =
            'Creates a new PDF without the pages you marked. Ideal for removing blank or sensitive pages.';
        break;
    }
    return Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey));
  }

  // ─── range editors ─────────────────────────────────────────────────────────
  List<Widget> _buildRangeEditors(
    ColorScheme colorScheme,
    PdfThemeExtension pdfTheme,
    bool disabled,
  ) {
    return [
      for (var i = 0; i < _ranges.length; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RANGE ${i + 1}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: disabled || _ranges.length == 1
                        ? null
                        : () {
                            setState(() {
                              final removed = _ranges.removeAt(i);
                              removed.from.dispose();
                              removed.to.dispose();
                            });
                          },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ranges[i].from,
                      enabled: !disabled,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'From page',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _ranges[i].to,
                      enabled: !disabled,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'To page',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    ];
  }
}

class _RangeRow {
  final TextEditingController from;
  final TextEditingController to;

  _RangeRow({required this.from, required this.to});
}
