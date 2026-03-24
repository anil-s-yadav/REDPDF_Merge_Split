import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/user_provider.dart';
import '../../providers/pdf_provider.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkUpdate();
    _initialCheck();
  }

  Future<void> _checkUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();

      switch (info.updateAvailability) {
        case UpdateAvailability.updateAvailable:
          await InAppUpdate.performImmediateUpdate();
          break;

        case UpdateAvailability.updateNotAvailable:
          log("No update available");
          break;

        case UpdateAvailability.developerTriggeredUpdateInProgress:
          await InAppUpdate.performImmediateUpdate();
          break;

        default:
          break;
      }
    } catch (e) {
      log("Error checking update: $e");
    }
  }

  Future<void> _initialCheck() async {
    if (!mounted) return;
    final status = await context
        .read<PermissionProvider>()
        .checkStoragePermission();
    if (status.isGranted && mounted) {
      // We force rescan here so the user always sees current files when opening the app.
      // The FileIndexService is now optimized with a fast scan followed by deep scan.
      await context.read<PdfProvider>().refreshSystemFiles(forceRescan: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initialCheck();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // _tabController.dispose();
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

    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.06, // approx 24px on typical screen
          ),
          child: DefaultTabController(
            length: 2,
            initialIndex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.03),
                _buildHeader(context, userProvider, colorScheme),
                SizedBox(height: size.height * 0.04),
                _buildActionButtons(context, pdfTheme, size),
                SizedBox(height: size.height * 0.04),
                _buildTabsAndSearch(colorScheme, pdfTheme, size),
                SizedBox(height: size.height * 0.02),
                Expanded(
                  child: TabBarView(
                    // controller: _tabController,
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
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    UserProvider user,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PDF - Merge and Split',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Combine or split your PDF files \nwith ease. ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        // GestureDetector(
        //   onTap: () => Navigator.pushNamed(context, '/upgrade'),
        //   child: PremiumAvatar(
        //     imageUrl: 'https://ui-avatars.com/api/?name=User',
        //     isPremium: user.isPremium,
        //     // size: 50,
        //   ),
        // ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    PdfThemeExtension pdfTheme,
    Size size,
  ) {
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
        SizedBox(width: size.width * 0.04),
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
    Size size,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            child: TabBar(
              // controller: _tabController,
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
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Scan for PDFs',
          onPressed: () async {
            final permProv = context.read<PermissionProvider>();
            final status = await permProv.ensureStoragePermission();
            if (!mounted) return;
            if (status.isGranted) {
              await context.read<PdfProvider>().refreshSystemFiles(
                forceRescan: true,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: colorScheme.primary.withAlpha(200),
                  content: Text('Scanning for PDFs...'),
                ),
              );
            } else if (status.isPermanentlyDenied) {
              await _showPermissionSettingsDialog(context);
            }
          },
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isSearching ? size.width * 0.35 : size.width * 0.1,
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
    final pdfProvider = context.read<PdfProvider>();
    final permProv = context.watch<PermissionProvider>();

    if (isSystem && !permProv.isStorageGranted) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_shared_outlined,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Permission Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'To show all PDFs on your device, the app needs "All files access" permission.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final status = await permProv.ensureStoragePermission();
                  if (status.isGranted && context.mounted) {
                    await context.read<PdfProvider>().refreshSystemFiles(
                      forceRescan: true,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Grant Access'),
              ),
            ],
          ),
        ),
      );
    }

    if (isSystem && pdfProvider.isScanningSystem) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Scanning storage for PDF files...',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSystem ? 'No indexed files found.' : 'No items in history.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (isSystem) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final status = await permProv.ensureStoragePermission();
                  if (!mounted) return;
                  if (status.isGranted) {
                    await context.read<PdfProvider>().refreshSystemFiles(
                      forceRescan: true,
                    );
                  } else if (status.isPermanentlyDenied) {
                    await _showPermissionSettingsDialog(context);
                  }
                },
                icon: const Icon(Icons.search),
                label: const Text('Scan Now'),
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
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
