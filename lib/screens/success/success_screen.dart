import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/pdf_provider.dart';
import '../../widgets/rate_us_dialog.dart';
import '../viewer/pdf_viewer_screen.dart';

class SuccessScreen extends StatefulWidget {
  final bool isSplit;

  const SuccessScreen({super.key, this.isSplit = false});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Show the rate-us dialog after the success animation finishes
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        RateUsDialog.showIfNeeded(context);
      }
    });
  }

  bool get isSplit => widget.isSplit;

  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSplit ? 'Split PDF' : 'Merge PDF'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.03),
            _buildSuccessAnimation(isSplit, pdfTheme),
            SizedBox(height: size.height * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isSplit
                      ? 'PDF Successfully Split'
                      : 'PDF Successfully Merged',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.stars, color: pdfTheme.gold, size: 24),
              ],
            ),
            SizedBox(height: size.height * 0.01),
            Text(
              isSplit
                  ? 'Your files have been split and saved to\nyour device.'
                  : 'Your files have been combined into a single\nhigh-quality document.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            SizedBox(height: size.height * 0.04),
            Expanded(
              child: _buildResultSection(
                context,
                isSplit,
                pdfTheme,
                colorScheme,
                size,
              ),
            ),
            SizedBox(height: size.height * 0.02),
            _buildActionButtons(context, isSplit, pdfTheme, size),
            SizedBox(height: size.height * 0.03),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation(bool isSplit, PdfThemeExtension pdfTheme) {
    final color = isSplit ? pdfTheme.splitPrimary : pdfTheme.mergePrimary;
    return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 80),
        )
        .animate()
        .scale(duration: 500.ms, curve: Curves.easeOutBack)
        .rotate(begin: -0.5, end: 0);
  }

  Widget _buildResultSection(
    BuildContext context,
    bool isSplit,
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    Size size,
  ) {
    final result = context.watch<PdfProvider>().lastResult;
    if (result == null) return const SizedBox.shrink();

    final List<String> paths = [];
    if (isSplit) {
      paths.addAll(result.outputPaths);
    } else if (result.outputPath != null) {
      paths.add(result.outputPath!);
    }

    if (paths.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            isSplit
                ? 'Generated File${paths.length > 1 ? 's (${paths.length})' : ''}'
                : 'Merged File',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: paths.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildFileItem(
                context,
                paths[index],
                isSplit,
                pdfTheme,
                colorScheme,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    String path,
    bool isSplit,
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      // padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PdfViewerScreen(path: path, title: p.basename(path)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.borderRadius24),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSplit
                  ? pdfTheme.splitContainer
                  : pdfTheme.mergeContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSplit ? Icons.content_cut : Icons.description,
              color: isSplit ? pdfTheme.splitPrimary : pdfTheme.mergePrimary,
            ),
          ),
          title: Text(
            p.basename(path),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: const Text(
            'Tap to view',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isSplit,
    PdfThemeExtension pdfTheme,
    Size size,
  ) {
    final color = isSplit ? pdfTheme.splitPrimary : pdfTheme.mergePrimary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final provider = context.watch<PdfProvider>();

    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            final result = provider.lastResult;
            if (result == null) return;
            if (!isSplit) {
              final path = result.outputPath;
              if (path == null) return;
              if (!context.mounted) return;
              await Future.delayed(const Duration(milliseconds: 200));
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PdfViewerScreen(path: path, title: 'Merged PDF'),
                ),
              );
              return;
            }
            if (isSplit) {
              if (result.outputPaths.isEmpty) return;
              if (result.outputPaths.length == 1) {
                final filePath = result.outputPaths.first;
                if (!context.mounted) return;
                await Future.delayed(const Duration(milliseconds: 200));
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      path: filePath,
                      title: p.basename(filePath),
                    ),
                  ),
                );
              } else {
                if (!context.mounted) return;
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Select file to view',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: result.outputPaths.length,
                          itemBuilder: (ctx, idx) {
                            final filePath = result.outputPaths[idx];
                            return ListTile(
                              leading: Icon(Icons.picture_as_pdf, color: color),
                              title: Text(p.basename(filePath)),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PdfViewerScreen(
                                      path: filePath,
                                      title: p.basename(filePath),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
              return;
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.open_in_new),
              const SizedBox(width: 12),
              Text(
                'Open PDF',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            OutlinedButton(
              onPressed: () async {
                final result = provider.lastResult;
                if (result == null) return;

                final paths = <String>[];
                if (!isSplit) {
                  if (result.outputPath != null) paths.add(result.outputPath!);
                } else {
                  paths.addAll(result.outputPaths);
                }
                if (paths.isEmpty) return;
                await SharePlus.instance.share(
                  ShareParams(files: paths.map((p) => XFile(p)).toList()),
                );
              },
              style: OutlinedButton.styleFrom(
                // minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: BorderSide(
                  color: isSplit
                      ? pdfTheme.splitPrimary.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.outline,
                ),
                backgroundColor: isSplit
                    ? pdfTheme.splitPrimary.withValues(alpha: 0.05)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_outlined, color: onSurface),
                  const SizedBox(width: 12),
                  Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final result = provider.lastResult;
                if (result == null) return;
                final path = !isSplit
                    ? result.outputPath
                    : (result.zipPath ??
                          (result.outputPaths.isNotEmpty
                              ? result.outputPaths.first
                              : null));
                if (path == null) return;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File is saved to Downloads/RedPdf')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                // minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: BorderSide(
                  color: isSplit
                      ? pdfTheme.splitPrimary.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.outline,
                ),
                backgroundColor: isSplit
                    ? pdfTheme.splitPrimary.withValues(alpha: 0.05)
                    : null,
              ),
              icon: Icon(Icons.download_rounded, color: color),
              label: Text(
                'Save again',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        // const SizedBox(height: 16),
      ],
    );
  }
}
