import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/pdf_provider.dart';

class SelectPdfScreen extends StatelessWidget {
  const SelectPdfScreen({super.key});

  Future<void> _pickFiles(BuildContext context, PdfProvider provider) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      final List<PdfFile> files = result.files.map((file) {
        return PdfFile(
          name: file.name,
          date: 'Just now',
          size: '${(file.size / 1024).toStringAsFixed(1)} KB',
          path: file.path,
        );
      }).toList();
      provider.addFiles(files);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfProvider = context.watch<PdfProvider>();
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select PDF'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: AppConstants.spacing24),
          _buildAddFilesContainer(context, pdfTheme, pdfProvider),
          const SizedBox(height: AppConstants.spacing32),
          _buildSelectedFilesHeader(
            colorScheme,
            pdfTheme,
            pdfProvider.selectedFiles.length,
          ),
          Expanded(
            child: _buildSelectedFilesList(context, colorScheme, pdfProvider),
          ),
          _buildBottomAction(context, pdfTheme, pdfProvider),
        ],
      ),
    );
  }

  Widget _buildAddFilesContainer(
    BuildContext context,
    PdfThemeExtension pdfTheme,
    PdfProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing24),
      child: InkWell(
        onTap: () => _pickFiles(context, provider),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius20),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacing24),
          decoration: BoxDecoration(
            color: pdfTheme.mergeContainer,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius20),
            border: Border.all(color: pdfTheme.mergePrimary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pdfTheme.mergePrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppConstants.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add more PDF files',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: pdfTheme.mergePrimary.withValues(alpha: 
                          0.8,
                        ), // Use themed primary
                      ),
                    ),
                    const Text(
                      'Select from your device storage',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedFilesHeader(
    ColorScheme colorScheme,
    PdfThemeExtension pdfTheme,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SELECTED FILES',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pdfTheme.mergeContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count FILES',
              style: TextStyle(
                color: pdfTheme.mergePrimary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFilesList(
    BuildContext context,
    ColorScheme colorScheme,
    PdfProvider provider,
  ) {
    final files = provider.selectedFiles;

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      itemCount: files.length + 1,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.spacing16),
      itemBuilder: (context, index) {
        if (index == files.length) {
          return InkWell(
            onTap: () => _pickFiles(context, provider),
            borderRadius: BorderRadius.circular(30),
            child: _buildDashContainer(colorScheme),
          );
        }
        final file = files[index];
        return Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.red),
            ),
            title: Text(
              file.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${file.date} \u2022 ${file.size}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () {
                    provider.removeFile(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${file.name} removed'),
                        action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () => provider.addFiles([file]),
                        ),
                      ),
                    );
                  },
                ),
                const Icon(Icons.drag_indicator, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashContainer(ColorScheme colorScheme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, color: Colors.grey, size: 20),
          SizedBox(width: 8),
          Text('Tap to add more', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    PdfThemeExtension pdfTheme,
    PdfProvider provider,
  ) {
    final fileCount = provider.selectedFiles.length;
    final canProcess = fileCount >= 2;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: canProcess
                ? () {
                    provider.processPdf();
                    Navigator.pushNamed(context, '/success');
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: pdfTheme.mergePrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: pdfTheme.mergePrimary.withValues(alpha: 0.3),
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upload_file),
                const SizedBox(width: 12),
                Text(
                  canProcess
                      ? 'Merge $fileCount Files'
                      : 'Select at least 2 files',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                'SECURE CLOUD PROCESSING',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
