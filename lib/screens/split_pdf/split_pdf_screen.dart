import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../models/pdf_models.dart';
import '../../providers/pdf_provider.dart';
import '../../services/file_index_service.dart';
import '../../permission/permission_provider.dart';
import '../success/success_screen.dart';
import '../viewer/pdf_viewer_screen.dart';
import 'package:permission_handler/permission_handler.dart';

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
  _SplitMode _mode = _SplitMode.extract;

  final List<_RangeRow> _ranges = [
    _RangeRow(
      from: TextEditingController(text: '1'),
      to: TextEditingController(text: '1'),
    ),
  ];
  final TextEditingController _extractController = TextEditingController(
    text: '1,2,3',
  );

  @override
  void dispose() {
    for (final r in _ranges) {
      r.from.dispose();
      r.to.dispose();
    }
    _extractController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final perm = context.read<PermissionProvider>();
    final status = await perm.ensureStoragePermission();
    if (!mounted) return;
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        await _showPermissionSettingsDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Storage permission is required to access PDFs on your device.',
            ),
          ),
        );
      }
      return;
    }
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
    });
    await _loadPageCount();
  }

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
      if (!mounted) return;
      setState(() => _pageCount = count);
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
            title: const Text('Password required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This PDF is locked. Enter password to view pages.'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password for this PDF',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (pwd != null && pwd.isNotEmpty && mounted) {
          await _loadPageCount(password: pwd);
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not read PDF pages: $e')));
      }
    }
  }

  List<PageRange> _buildRanges() {
    if (_mode == _SplitMode.range) {
      final out = <PageRange>[];
      for (final r in _ranges) {
        final from = int.tryParse(r.from.text.trim());
        final to = int.tryParse(r.to.text.trim());
        if (from == null || to == null) continue;
        out.add(PageRange(from, to));
      }
      return out;
    }

    final raw = _extractController.text;
    final nums =
        raw
            .split(RegExp(r'[,\s]+'))
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();
    final ranges = nums.map((n) => PageRange(n, n)).toList();
    return ranges;
  }

  Future<void> _runSplit(PdfProvider provider) async {
    final path = _inputPath;
    if (path == null) return;
    final ranges = _buildRanges();
    if (ranges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid ranges/pages.')),
      );
      return;
    }
    try {
      final perm = context.read<PermissionProvider>();
      final status = await perm.ensureStoragePermission();
      if (!mounted) return;
      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          await _showPermissionSettingsDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage permission is required to access PDFs on your device.',
              ),
            ),
          );
        }
        return;
      }
      final effectiveRanges =
          _mode == _SplitMode.everyPage && _pageCount != null
          ? List<PageRange>.generate(
              _pageCount!,
              (i) => PageRange(i + 1, i + 1),
            )
          : ranges;

      final res = await provider.split(
        inputPath: path,
        ranges: effectiveRanges,
      );
      if (res == null) {
        if (!mounted) return;
        if (provider.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(provider.error!)));
        }
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SuccessScreen(isSplit: true)),
      );
    } on PdfPasswordRequired catch (e) {
      if (!mounted) return;
      final controller = TextEditingController();
      final pwd = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Password required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter password for ${e.name}'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (pwd == null || pwd.isEmpty) return;
      final effectiveRanges =
          _mode == _SplitMode.everyPage && _pageCount != null
          ? List<PageRange>.generate(
              _pageCount!,
              (i) => PageRange(i + 1, i + 1),
            )
          : ranges;
      await provider.split(
        inputPath: path,
        ranges: effectiveRanges,
        password: pwd,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SuccessScreen(isSplit: true)),
      );
    }
  }

  Future<void> _showPermissionSettingsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission required'),
        content: const Text(
          'Storage permission is permanently denied. '
          'Please enable it in system settings to manage PDFs on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<PdfProvider>();

    final routeArg = ModalRoute.of(context)?.settings.arguments;
    if (_inputPath == null && routeArg is String) {
      _inputPath = routeArg;
      _inputName = routeArg.split(Platform.pathSeparator).last;
    }

    final path = _inputPath;
    final canSplit = path != null && !provider.isProcessing;

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
                      });
                    },
              child: const Text('Reselect'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfViewerScreen(
                              path: path,
                              title: _inputName ?? 'PDF',
                            ),
                          ),
                        );
                      },
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
            const SizedBox(height: 8),

            const SizedBox(height: 16),
            if (_mode == _SplitMode.range) ...[
              _buildRangeHeader(pdfTheme, provider.isProcessing),
              const SizedBox(height: 12),
              ..._buildRangeEditors(
                colorScheme,
                pdfTheme,
                provider.isProcessing,
              ),
            ] else if (_mode == _SplitMode.extract ||
                _mode == _SplitMode.delete) ...[
              Text(
                _mode == _SplitMode.delete ? 'Remove pages' : 'Extract pages',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _extractController,
                enabled: !provider.isProcessing,
                decoration: const InputDecoration(
                  hintText: 'Example: 1,2,5,10 or 3-7',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => provider.requestCancel(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pdfTheme.splitPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

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
            child: Icon(Icons.picture_as_pdf, color: pdfTheme.splitPrimary),
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
                Text(
                  has
                      ? '${_pageCount ?? '—'} Pages'
                      : 'Tap "Select PDF" to begin',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle(PdfThemeExtension pdfTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => setState(() => _mode = _SplitMode.extract),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _mode == _SplitMode.extract
                    ? colorScheme.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ' Extract ',
                style: TextStyle(
                  color: _mode == _SplitMode.extract
                      ? pdfTheme.splitPrimary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _mode = _SplitMode.everyPage),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _mode == _SplitMode.everyPage
                    ? colorScheme.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ' Every Page ',
                style: TextStyle(
                  color: _mode == _SplitMode.everyPage
                      ? pdfTheme.splitPrimary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _mode = _SplitMode.range),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _mode == _SplitMode.range
                    ? colorScheme.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ' By Range ',
                style: TextStyle(
                  color: _mode == _SplitMode.range
                      ? pdfTheme.splitPrimary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _mode = _SplitMode.delete),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _mode == _SplitMode.delete
                    ? colorScheme.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ' Delete Pages ',
                style: TextStyle(
                  color: _mode == _SplitMode.delete
                      ? pdfTheme.splitPrimary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildModeDescription() {
    String subtitle;

    switch (_mode) {
      case _SplitMode.extract:
        subtitle =
            'Create a new PDF that only contains the pages you select (e.g. chapters, invoices, certificates).';
        break;
      case _SplitMode.everyPage:
        subtitle =
            'Turn each page into its own PDF file. Useful for exporting many invoices or certificates at once.';
        break;
      case _SplitMode.range:
        subtitle =
            'Choose page ranges like 1–5, 6–10 etc. Each range becomes a separate PDF (chapters, sections, bundles).';
        break;
      case _SplitMode.delete:
        subtitle =
            'Create a new PDF without the pages you list. Ideal for deleting blank or sensitive pages.';
        break;
    }

    return Text(
      subtitle,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  List<Widget> _buildRangeEditors(
    ColorScheme colorScheme,
    PdfThemeExtension pdfTheme,
    bool disabled,
  ) {
    final out = <Widget>[];
    for (var i = 0; i < _ranges.length; i++) {
      final row = _ranges[i];
      out.add(
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
                      controller: row.from,
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
                      controller: row.to,
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
      );
    }
    return out;
  }
}

class _RangeRow {
  final TextEditingController from;
  final TextEditingController to;

  _RangeRow({required this.from, required this.to});
}
