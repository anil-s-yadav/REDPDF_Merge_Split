import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../models/pdf_models.dart';
import '../../providers/pdf_provider.dart';
import '../success/success_screen.dart';

enum ProcessingJobType { merge, split, extract }

class ProcessingScreen extends StatefulWidget {
  final ProcessingJobType type;
  final String estimatedSize;
  final bool isLarge;

  // For merge
  final Map<String, String> passwords;

  // For split/extract
  final String? inputPath;
  final List<PageRange>? ranges;
  final List<int>? pages;
  final String? password;
  final String? suffix;

  const ProcessingScreen({
    super.key,
    required this.type,
    required this.estimatedSize,
    required this.isLarge,
    this.passwords = const {},
    this.inputPath,
    this.ranges,
    this.pages,
    this.password,
    this.suffix,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        _started = true;
        _runTask();
      }
    });
  }

  Future<void> _runTask() async {
    final provider = context.read<PdfProvider>();
    PdfJobResult? result;

    try {
      if (widget.type == ProcessingJobType.merge) {
        result = await provider.mergeSelected(passwords: widget.passwords);
      } else if (widget.type == ProcessingJobType.split) {
        result = await provider.split(
          inputPath: widget.inputPath!,
          ranges: widget.ranges!,
          password: widget.password,
        );
      } else if (widget.type == ProcessingJobType.extract) {
        result = await provider.extract(
          inputPath: widget.inputPath!,
          pages: widget.pages!,
          password: widget.password,
          outputNameSuffix: widget.suffix,
        );
      }

      if (!mounted) return;

      if (result != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SuccessScreen(isSplit: widget.type != ProcessingJobType.merge),
          ),
        );
      } else if (provider.error != null) {
        // If it was cancelled, provider.error might be "Processing was cancelled"
        // We handle cancellation by going back, which is handled by WillPopScope/Back button
        if (provider.error!.contains('cancelled')) {
          // Handled by pop
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(provider.error!)));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('cancelled')) {
        // Cancelled
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<bool> _onWillPop() async {
    final provider = context.read<PdfProvider>();
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Processing?'),
        content: const Text(
          'Going back will stop the current PDF process. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Processing'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.requestCancel();
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: pdfTheme.mergePrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PdfProvider>();
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    // Get primary color based on job type
    final primaryColor = widget.type == ProcessingJobType.merge
        ? pdfTheme.mergePrimary
        : pdfTheme.splitPrimary;

    final containerColor = widget.type == ProcessingJobType.merge
        ? pdfTheme.mergeContainer
        : pdfTheme.splitContainer;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withValues(alpha: 0.05),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon/Animation area
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: containerColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.type == ProcessingJobType.merge
                          ? Icons.merge_type
                          : Icons.call_split_rounded,
                      size: 55,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Title
                  Text(
                    widget.type == ProcessingJobType.merge
                        ? 'Merging PDFs'
                        : 'Splitting PDF',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Estimated Size & Details
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Estimated Size: ${widget.estimatedSize}',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.type == ProcessingJobType.merge) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${context.read<PdfProvider>().selectedFiles.length} PDF files',
                            style: TextStyle(
                              color: primaryColor.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Progress Indicator
                  SizedBox(
                    width: size.width * 0.7,
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          color: primaryColor,
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.processingMessage ?? 'Please wait while we process your file...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Large file message
                  if (widget.isLarge)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: const Text(
                              'We are processing a very large file, please keep patience.',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Cancel Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final shouldPop = await _onWillPop();
                        if (shouldPop && mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel & Go Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                        minimumSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
