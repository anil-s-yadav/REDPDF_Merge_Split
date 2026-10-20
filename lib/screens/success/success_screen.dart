import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:stitch/widgets/ad_banner_widget.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/pdf_provider.dart';
import '../../widgets/rate_us_dialog.dart';
import '../../services/rate_us_service.dart';
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
    // Record task completion and show review prompt after success animation
    _promptReviewAfterDelay();
  }

  Future<void> _promptReviewAfterDelay() async {
    await RateUsService.recordTaskCompletion();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      RateUsDialog.showIfNeeded(context);
    }
  }

  bool get isSplit => widget.isSplit;

  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          child: Column(
            children: [
              _buildSuccessAnimation(isSplit, pdfTheme),
              SizedBox(height: size.height * 0.03),
              FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isSplit
                          ? 'PDF Successfully Split'
                          : 'PDF Successfully Merged',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.check, color: Colors.green, size: 24),
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                isSplit
                    ? 'Your files have been split and saved to\nyour device.'
                    : 'Your files have been combined into a single\nhigh-quality document.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
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
              _buildActionButtons(
                context,
                size,
                isSplit,
                pdfTheme,
                colorScheme,
              ),
              SizedBox(height: size.height * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation(bool isSplit, PdfThemeExtension pdfTheme) {
    final color = isSplit ? pdfTheme.splitPrimary : pdfTheme.mergePrimary;
    return Container(
          width: 80,
          height: 80,
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
        SizedBox(height: size.height * 0.01),
        // Banner ad here
        const Center(
          child: AdBannerWidget(bannerType: AdBannerType.fourByThree),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: _PdfFirstPageThumbnail(
            path: path,
            isSplit: isSplit,
            pdfTheme: pdfTheme,
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
    Size size,
    bool isSplit,
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
  ) {
    final color = isSplit ? pdfTheme.splitPrimary : pdfTheme.mergePrimary;
    final provider = context.watch<PdfProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Main Action: Back to homescreen ──
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 1,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_rounded, size: 22),
              SizedBox(width: 8),
              Text(
                'Back to homescreen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Secondary Actions: Share | Save again | Open ──
        Row(
          children: [
            Expanded(
              child: _buildSecondaryActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: color,
                colorScheme: colorScheme,
                onPressed: () => _handleShare(provider, isSplit),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSecondaryActionButton(
                icon: Icons.download_rounded,
                label: 'Save again',
                color: color,
                colorScheme: colorScheme,
                onPressed: () => _handleSaveAgain(context, provider, isSplit),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSecondaryActionButton(
                icon: Icons.open_in_new_rounded,
                label: 'Open',
                color: color,
                colorScheme: colorScheme,
                onPressed: () =>
                    _handleOpenPdf(context, provider, isSplit, color, pdfTheme),
              ),
            ),
          ],
        ),
        // Banner ad here
        const Center(child: AdBannerWidget(bannerType: AdBannerType.standard)),
      ],
    );
  }

  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required ColorScheme colorScheme,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        backgroundColor: color.withValues(alpha: 0.05),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShare(PdfProvider provider, bool isSplit) async {
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
  }

  Future<void> _handleSaveAgain(
    BuildContext context,
    PdfProvider provider,
    bool isSplit,
  ) async {
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
        const SnackBar(content: Text('File is saved to Downloads')),
      );
    }
  }

  Future<void> _handleOpenPdf(
    BuildContext context,
    PdfProvider provider,
    bool isSplit,
    Color color,
    PdfThemeExtension pdfTheme,
  ) async {
    final result = provider.lastResult;
    if (result == null) return;

    if (!isSplit) {
      final path = result.outputPath;
      if (path == null || !context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(path: path, title: 'Merged PDF'),
        ),
      );
      return;
    }

    if (result.outputPaths.isEmpty) return;

    if (result.outputPaths.length == 1) {
      final filePath = result.outputPaths.first;
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PdfViewerScreen(path: filePath, title: p.basename(filePath)),
        ),
      );
    } else {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select file to view',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: result.outputPaths.length,
                itemBuilder: (ctx, idx) {
                  final filePath = result.outputPaths[idx];
                  return ListTile(
                    leading: _PdfFirstPageThumbnail(
                      path: filePath,
                      isSplit: true,
                      pdfTheme: pdfTheme,
                    ),
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
  }
}

class _PdfFirstPageThumbnail extends StatefulWidget {
  final String path;
  final bool isSplit;
  final PdfThemeExtension pdfTheme;

  const _PdfFirstPageThumbnail({
    required this.path,
    required this.isSplit,
    required this.pdfTheme,
  });

  @override
  State<_PdfFirstPageThumbnail> createState() => _PdfFirstPageThumbnailState();
}

class _PdfFirstPageThumbnailState extends State<_PdfFirstPageThumbnail> {
  Uint8List? _previewBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFirstPagePreview();
  }

  @override
  void didUpdateWidget(covariant _PdfFirstPageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _loadFirstPagePreview();
    }
  }

  Future<void> _loadFirstPagePreview() async {
    try {
      final doc = await pdfx.PdfDocument.openFile(widget.path);
      if (doc.pagesCount > 0) {
        final page = await doc.getPage(1);
        final pageImage = await page.render(
          width: page.width / 3,
          height: page.height / 3,
          format: pdfx.PdfPageImageFormat.jpeg,
        );
        await page.close();
        await doc.close();
        if (mounted && pageImage != null) {
          setState(() {
            _previewBytes = pageImage.bytes;
            _isLoading = false;
          });
          return;
        }
      } else {
        await doc.close();
      }
    } catch (_) {
      // Fallback
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSplit
        ? widget.pdfTheme.splitPrimary
        : widget.pdfTheme.mergePrimary;
    final containerColor = widget.isSplit
        ? widget.pdfTheme.splitContainer
        : widget.pdfTheme.mergeContainer;

    if (_previewBytes != null) {
      return Container(
        width: 44,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(_previewBytes!, fit: BoxFit.cover),
      );
    }

    if (_isLoading) {
      return Container(
        width: 44,
        height: 56,
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      );
    }

    // Fallback icon
    return Container(
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        widget.isSplit ? Icons.content_cut : Icons.description,
        color: color,
      ),
    );
  }
}
