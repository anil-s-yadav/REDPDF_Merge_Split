import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/pdf_provider.dart';
import '../../models/pdf_models.dart';
import '../processing/processing_screen.dart';
// import 'package:permission_handler/permission_handler.dart';

class SelectPdfScreen extends StatelessWidget {
  const SelectPdfScreen({super.key});

  Future<void> _pickFiles(BuildContext context, PdfProvider provider) async {
    // final permissionProvider = context.read<PermissionProvider>();
    // final status = await permissionProvider.ensureStoragePermission();
    // if (!context.mounted) return;
    // if (!status.isGranted) {
    //   if (status.isPermanentlyDenied) {
    //     await _showPermissionSettingsDialog(context);
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text(
    //           'Storage permission is required to access PDFs on your device.',
    //         ),
    //       ),
    //     );
    //   }
    //   return;
    // }

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

  Future<void> _merge(
    BuildContext context,
    PdfProvider provider, {
    Map<String, String> passwords = const {},
  }) async {
    final bytes = await provider.getSelectedFilesTotalSize();
    final sizeStr = provider.formatBytes((bytes * 0.98).toInt());
    final isLarge = bytes > 2 * 1024 * 1024; // > 2MB

    if (!context.mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(
            type: ProcessingJobType.merge,
            estimatedSize: sizeStr,
            isLarge: isLarge,
            passwords: passwords,
          ),
        ),
      );

      // Password handling is usually initiated inside provider.mergeSelected,
      // but here we might need to catch it if retry is needed.
      // However, ProcessingScreen runs the task. If it throws password required,
      // we need to handle it.
    } on PdfPasswordRequired catch (e) {
      if (!context.mounted) return;
      final controller = TextEditingController();
      final pwd = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Password required'),
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
      if (!context.mounted) return;
      await _merge(context, provider, passwords: {e.path: pwd});
    }
  }

  // Future<void> _showPermissionSettingsDialog(BuildContext context) async {
  //   await showDialog<void>(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: const Text('Permission required'),
  //       content: const Text(
  //         'Storage permission is permanently denied. '
  //         'Please enable it in system settings to manage PDFs on this device.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx),
  //           child: const Text('Cancel'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             Navigator.pop(ctx);
  //             await openAppSettings();
  //           },
  //           child: const Text('Open Settings'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final pdfProvider = context.watch<PdfProvider>();
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select PDF'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: size.height * 0.03),
          _buildAddFilesContainer(context, pdfTheme, pdfProvider, size),
          SizedBox(height: size.height * 0.04),
          _buildSelectedFilesHeader(
            colorScheme,
            pdfTheme,
            pdfProvider.selectedFiles.length,
            size,
          ),
          Expanded(
            child: AbsorbPointer(
              absorbing: pdfProvider.isProcessing,
              child: _buildSelectedFilesList(
                context,
                colorScheme,
                textTheme,
                pdfProvider,
              ),
            ),
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
    Size size,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
      child: InkWell(
        onTap: provider.isProcessing
            ? null
            : () => _pickFiles(context, provider),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius20),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacing24),
          decoration: BoxDecoration(
            color: pdfTheme.mergeContainer,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius20),
            border: Border.all(
              color: pdfTheme.mergePrimary.withValues(alpha: 0.2),
            ),
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
                        color: pdfTheme.mergePrimary.withValues(
                          alpha: 0.8,
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
    Size size,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
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
    TextTheme textTheme,
    PdfProvider provider,
  ) {
    final files = provider.selectedFiles;

    final size = MediaQuery.sizeOf(context);

    return ReorderableListView.builder(
      padding: EdgeInsets.all(size.width * 0.06),
      itemCount: files.length + 1,
      onReorder: provider.reorderSelected,
      proxyDecorator: (child, index, animation) => Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
      itemBuilder: (context, index) {
        if (index == files.length) {
          return Padding(
            key: const ValueKey('__add_more__'),
            padding: const EdgeInsets.only(top: AppConstants.spacing16),
            child: InkWell(
              onTap: () => _pickFiles(context, provider),
              borderRadius: BorderRadius.circular(30),
              child: _buildDashContainer(colorScheme),
            ),
          );
        }
        final file = files[index];
        return Card(
          key: ValueKey(file.path ?? '${file.name}-$index'),
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
              style: textTheme.titleMedium,
              // style: TextStyle(
              //   fontWeight: FontWeight.w600,
              //   color: colorScheme.,
              // ),
            ),
            subtitle: Text(
              '${file.date} \u2022 ${file.size}',
              style: textTheme.bodyMedium,
            ),
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
                        persist: false,
                        // duration: Durations.long4,
                        action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () => provider.addFiles([file]),
                        ),
                      ),
                    );
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
    if (provider.isProcessing) {
      return const SizedBox.shrink(); // Processing is now on its own screen
    }

    final fileCount = provider.selectedFiles.length;
    final canProcess = fileCount >= 2;

    final size = MediaQuery.sizeOf(context);

    return Padding(
      padding: EdgeInsets.all(size.width * 0.06),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: canProcess
                ? () async {
                    await _merge(context, provider);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: pdfTheme.mergePrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: pdfTheme.mergePrimary.withValues(
                alpha: 0.3,
              ),
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
                'SECURE AND FAST PROCESSING',
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
