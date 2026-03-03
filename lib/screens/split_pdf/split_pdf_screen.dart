import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/pdf_provider.dart';
import '../success/success_screen.dart';

class SplitPdfScreen extends StatelessWidget {
  const SplitPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Split PDF'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectedFileTile(pdfTheme, colorScheme),
            const SizedBox(height: 32),
            _buildTabToggle(pdfTheme, colorScheme),
            const SizedBox(height: 32),
            _buildRangeHeader(pdfTheme),
            const SizedBox(height: 16),
            _buildRangeItem(colorScheme, pdfTheme, 1, '1', '10'),
            const SizedBox(height: 16),
            _buildRangeItem(
              colorScheme,
              pdfTheme,
              2,
              '11',
              '20',
              isDashed: true,
            ),
            const SizedBox(height: 32),
            const Text(
              'Page Selection Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPagePreview(pdfTheme, colorScheme),
            const SizedBox(height: 32),
            _buildBottomSummary(pdfTheme),
            const SizedBox(height: 16),
            _buildSplitButton(context, pdfTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileTile(
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pdfTheme.splitContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.picture_as_pdf, color: pdfTheme.splitPrimary),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q3_Financial_Projections_Fin...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '12.4 MB \u2022 48 Pages',
                  style: TextStyle(color: Colors.grey),
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
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Split by Range',
                  style: TextStyle(
                    color: pdfTheme.splitPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Center(
                child: Text(
                  'Extract Pages',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeHeader(PdfThemeExtension pdfTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Define Ranges',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          onPressed: () {},
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

  Widget _buildRangeItem(
    ColorScheme colorScheme,
    PdfThemeExtension pdfTheme,
    int index,
    String from,
    String to, {
    bool isDashed = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDashed
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RANGE $index',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From page',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    _buildPageInput(colorScheme, from),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To page',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    _buildPageInput(colorScheme, to),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageInput(ColorScheme colorScheme, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPagePreview(
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildPageThumbnail(pdfTheme, colorScheme, 1, true),
        _buildPageThumbnail(pdfTheme, colorScheme, 2, false),
        _buildPageThumbnail(pdfTheme, colorScheme, 3, true),
        _buildPageThumbnail(pdfTheme, colorScheme, 4, false),
      ],
    );
  }

  Widget _buildPageThumbnail(
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    int page,
    bool isSelected,
  ) {
    return Container(
      width: 100,
      height: 140,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: pdfTheme.splitPrimary, width: 2)
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Text('$page', style: const TextStyle(color: Colors.grey)),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? pdfTheme.splitPrimary : colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(PdfThemeExtension pdfTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Total Output Files:', style: TextStyle(color: Colors.grey)),
        Text(
          '2 PDFs',
          style: TextStyle(
            color: pdfTheme.splitPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitButton(BuildContext context, PdfThemeExtension pdfTheme) {
    return ElevatedButton(
      onPressed: () async {
        await context.read<PdfProvider>().processPdf(isSplit: true);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SuccessScreen(isSplit: true),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: pdfTheme.splitPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call_split_rounded),
          SizedBox(width: 12),
          Text(
            'Split PDF Now',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
