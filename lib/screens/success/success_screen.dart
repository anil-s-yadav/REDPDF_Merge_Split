import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/pdf_provider.dart';
import '../../permission/permission_provider.dart';
import '../viewer/pdf_viewer_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class SuccessScreen extends StatelessWidget {
  final bool isSplit;

  const SuccessScreen({super.key, this.isSplit = false});

  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Success'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildSuccessAnimation(isSplit, pdfTheme),
            const SizedBox(height: 32),
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
            const SizedBox(height: 16),
            const Text(
              'Your files have been combined into a single high-\nquality document. Premium features were applied.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            _buildFileCard(context, isSplit, pdfTheme, colorScheme),
            const Spacer(),
            _buildActionButtons(context, isSplit, pdfTheme),
            const SizedBox(height: 24),
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

  Widget _buildFileCard(
    BuildContext context,
    bool isSplit,
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
  ) {
    final result = context.watch<PdfProvider>().lastResult;
    final title = isSplit
        ? (result?.zipPath != null
              ? p.basename(result!.zipPath!)
              : (result?.outputPaths.isNotEmpty == true
                    ? p.basename(result!.outputPaths.first)
                    : 'split_files'))
        : (result?.outputPath != null
              ? p.basename(result!.outputPath!)
              : 'merged_document.pdf');
    final subtitle = isSplit
        ? '${result?.outputPaths.length ?? 0} files created'
        : (result?.outputPath != null ? result!.outputPath! : '');
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle.isEmpty
                      ? (isSplit ? 'Split complete' : 'Merge complete')
                      : subtitle,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isSplit,
    PdfThemeExtension pdfTheme,
  ) {
    final color = isSplit ? pdfTheme.splitPrimary : pdfTheme.mergePrimary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final provider = context.watch<PdfProvider>();
    final permProv = context.read<PermissionProvider>();

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PdfViewerScreen(path: path, title: 'Merged PDF'),
                ),
              );
              return;
            }
            if (result.outputPaths.isNotEmpty) {
              await OpenFilex.open(result.outputPaths.first);
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
                isSplit ? 'Open Files' : 'Open PDF',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () async {
            final result = provider.lastResult;
            if (result == null) return;
            final status = await permProv.ensureStoragePermission();
            if (!context.mounted) return;
            if (!status.isGranted) {
              if (status.isPermanentlyDenied) {
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
            minimumSize: const Size(double.infinity, 60),
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
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () async {
            final result = provider.lastResult;
            if (result == null) return;
            // "Save to device" is platform dependent; we implement as "open in system"
            // or "share" to a file manager destination.
            final path = !isSplit
                ? result.outputPath
                : (result.zipPath ??
                      (result.outputPaths.isNotEmpty
                          ? result.outputPaths.first
                          : null));
            if (path == null) return;
            await OpenFilex.open(path);
          },
          icon: Icon(Icons.download_rounded, color: color),
          label: Text(
            'Save to Device',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
