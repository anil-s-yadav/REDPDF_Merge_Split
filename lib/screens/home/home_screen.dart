import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/user_provider.dart';
import '../../providers/pdf_provider.dart';
import '../../widgets/premium_avatar.dart';
import '../../widgets/action_pill.dart';
import '../../models/pdf_models.dart';
import '../../permission/permission_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../split_pdf/split_pdf_screen.dart' show SplitPdfScreen;
import '../viewer/pdf_viewer_screen.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final permissionProvider = context.read<PermissionProvider>();
      final status = await permissionProvider.ensureStoragePermission();
      if (!mounted) return;
      if (status.isGranted) {
        await context.read<PdfProvider>().refreshSystemFiles();
      } else if (status.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Storage permission is required to access PDFs on your device.',
            ),
          ),
        );
      } else if (status.isPermanentlyDenied) {
        if (!mounted) return;
        _showPermissionSettingsDialog(context);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final pdfProvider = context.watch<PdfProvider>();
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final query = _searchController.text.toLowerCase();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.spacing24),
              _buildHeader(context, userProvider),
              const SizedBox(height: AppConstants.spacing32),
              _buildActionButtons(context, pdfTheme),
              const SizedBox(height: AppConstants.spacing32),
              _buildTabsAndSearch(colorScheme, pdfTheme),
              const SizedBox(height: AppConstants.spacing16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFileList(
                      pdfProvider.systemFiles
                          .where((f) => f.name.toLowerCase().contains(query))
                          .toList(),
                      pdfTheme,
                      isSystem: true,
                    ), //system files
                    _buildFileList(
                      pdfProvider.history
                          .where(
                            (f) => f.name.toLowerCase().contains(
                              _searchController.text.toLowerCase(),
                            ),
                          )
                          .toList(),
                      pdfTheme,
                      isHistory: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProvider user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF - Merge and Split',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Combine or split your PDF files \nwith ease. ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/upgrade'),
          child: PremiumAvatar(
            imageUrl: 'https://ui-avatars.com/api/?name=User',
            isPremium: user.isPremium,
            // size: 50,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, PdfThemeExtension pdfTheme) {
    return Row(
      children: [
        ActionPill(
          title: 'PDF Merge',
          icon: Icons.upload_file,
          backgroundColor: pdfTheme.mergeContainer,
          iconBackgroundColor: pdfTheme.mergePrimary,
          textColor: pdfTheme.mergePrimary,
          onTap: () => Navigator.pushNamed(context, '/select-pdf'),
        ),
        const SizedBox(width: AppConstants.spacing16),
        ActionPill(
          title: 'Split PDF',
          icon: Icons.call_split_rounded,
          backgroundColor: pdfTheme.splitContainer,
          iconBackgroundColor: pdfTheme.splitPrimary,
          textColor: pdfTheme.splitPrimary,
          onTap: () => Navigator.pushNamed(context, '/split-pdf'),
        ),
      ],
    );
  }

  Widget _buildTabsAndSearch(
    ColorScheme colorScheme,
    PdfThemeExtension pdfTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              labelColor: pdfTheme.mergePrimary,
              unselectedLabelColor: colorScheme.onSurface.withValues(
                alpha: 0.5,
              ),
              indicatorColor: pdfTheme.mergePrimary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              // labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [
                Tab(text: 'All Files'),
                Tab(text: 'History'),
              ],
              dividerColor: Colors.transparent,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isSearching ? 120 : 40,
          child: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => setState(() => _isSearching = false),
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _isSearching = true),
                ),
        ),
        if (!_isSearching)
          TextButton(
            onPressed: () {
              _confirmClearHistory(context);
            },
            child: Text(
              'CLEAR ALL',
              style: TextStyle(
                color: pdfTheme.splitPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This will remove all history entries.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<PdfProvider>().clearHistory();
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

  Widget _buildFileList(
    List<PdfFile> files,
    PdfThemeExtension pdfTheme, {
    bool isHistory = false,
    bool isSystem = false,
  }) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSystem ? 'No files indexed yet' : 'No files yet',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (isSystem) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final permProv = context.read<PermissionProvider>();
                  final status = await permProv.ensureStoragePermission();
                  if (!context.mounted) return;
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
                  await context.read<PdfProvider>().refreshSystemFiles(
                    forceRescan: true,
                  );
                },
                child: const Text('Scan'),
              ),
            ],
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: files.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.spacing12),
      itemBuilder: (context, index) {
        final file = files[index];
        final isMerge = file.isMerge;
        final primaryColor = isMerge
            ? pdfTheme.mergePrimary
            : pdfTheme.splitPrimary;
        final containerColor = isMerge
            ? pdfTheme.mergeContainer
            : pdfTheme.splitContainer;

        return Card(
          shadowColor: containerColor,
          elevation: 0,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isMerge ? Icons.description : Icons.content_cut,
                color: primaryColor,
              ),
            ),
            title: Text(
              file.name,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
            subtitle: Text(
              '${file.date} \u2022 ${file.size}',
              style: const TextStyle(fontWeight: FontWeight.w100, fontSize: 10),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                final path = file.path;
                final pdfProv = context.read<PdfProvider>();
                final permProv = context.read<PermissionProvider>();
                if (value == 'open' && path != null) {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PdfViewerScreen(path: path, title: file.name),
                    ),
                  );
                } else if (value == 'merge' && path != null) {
                  pdfProv.addFiles([
                    PdfFile(
                      name: file.name,
                      date: file.date,
                      size: file.size,
                      path: path,
                      isMerge: true,
                    ),
                  ]);
                  if (!mounted) return;
                  Navigator.pushNamed(context, '/select-pdf');
                } else if (value == 'split' && path != null) {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SplitPdfScreen(),
                      settings: RouteSettings(arguments: path),
                    ),
                  );
                } else if (value == 'share' && path != null) {
                  final status = await permProv.ensureStoragePermission();
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
                  await SharePlus.instance.share(
                    ShareParams(files: [XFile(path)]),
                  );
                } else if (value == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete file?'),
                      content: Text('Delete "${file.name}" from device?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && mounted) {
                    await pdfProv.deleteFile(
                      file,
                      fromHistory: isHistory,
                      fromSystem: isSystem,
                    );
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'open', child: Text('Open')),
                PopupMenuItem(value: 'merge', child: Text('Select to merge')),
                PopupMenuItem(value: 'split', child: Text('Select to split')),
                PopupMenuItem(value: 'share', child: Text('Share')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
            onTap: file.path == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PdfViewerScreen(path: file.path!, title: file.name),
                      ),
                    );
                  },
          ),
        );
      },
    );
  }
}
