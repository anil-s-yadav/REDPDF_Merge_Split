import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';

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
            _buildCloudBackupToggle(isSplit, pdfTheme, colorScheme),
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
                  isSplit ? 'split_files_2024...' : 'merged_document_20...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isSplit ? '3 files created' : '2.4 MB \u2022 12 Pages',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(
            Icons.visibility_outlined,
            color: isSplit ? pdfTheme.splitPrimary : pdfTheme.mergePrimary,
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

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {},
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
          onPressed: () {},
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
          onPressed: () {},
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

  Widget _buildCloudBackupToggle(
    bool isSplit,
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cloud Backup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Automatically sync to your drive',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: true,
            onChanged: (val) {},
            activeThumbColor: isSplit
                ? pdfTheme.splitPrimary
                : pdfTheme.mergePrimary,
          ),
        ],
      ),
    );
  }
}
