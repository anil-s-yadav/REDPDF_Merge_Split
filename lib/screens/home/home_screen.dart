import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/pdf_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/action_pill.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../models/pdf_models.dart';

import '../split_pdf/split_pdf_screen.dart' show SplitPdfScreen;
import '../../services/file_opener_service.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!kDebugMode) {
      _checkUpdate();
    }
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _closeSearch() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pdfProvider = context.watch<PdfProvider>();
    final userProvider = context.watch<UserProvider>();
    final isPremium = userProvider.isPremium;
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _searchController.text.toLowerCase();

    final size = MediaQuery.sizeOf(context);

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.06, // approx 24px on typical screen
            ),
            child: DefaultTabController(
              length: 2,
              initialIndex: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // SizedBox(height: size.height * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildHeader(context, colorScheme)),
                      const SizedBox(width: 8),
                      _buildPremiumStatusButton(
                        context,
                        isPremium,
                        pdfTheme,
                        isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.025),
                  _buildActionButtons(context, pdfTheme, size),
                  SizedBox(height: size.height * 0.025),
                  // Banner ad here
                  const Center(
                    child: AdBannerWidget(bannerType: AdBannerType.standard),
                  ),
                  // SizedBox(height: size.height * 0.01),
                  _buildTabsAndSearch(colorScheme, pdfTheme, size),
                  SizedBox(height: 6),
                  Expanded(
                    child: TabBarView(
                      // controller: _tabController,
                      children: [
                        _buildFileList(
                          pdfProvider.history
                              .where(
                                (f) =>
                                    f.isMerge &&
                                    f.name.toLowerCase().contains(query),
                              )
                              .toList(),
                          pdfTheme,
                          isHistory: true,
                        ), //merge history
                        _buildFileList(
                          pdfProvider.history
                              .where(
                                (f) =>
                                    !f.isMerge &&
                                    f.name.toLowerCase().contains(query),
                              )
                              .toList(),
                          pdfTheme,
                          isHistory: true,
                        ), //split history
                      ],
                    ),
                  ),

                  SizedBox(height: 2),
                  // Banner ad here
                  const Center(
                    child: AdBannerWidget(bannerType: AdBannerType.standard),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumStatusButton(
    BuildContext context,
    bool isPremium,
    PdfThemeExtension pdfTheme,
    bool isDark,
  ) {
    return Tooltip(
      message: isPremium ? 'RedPDF PRO Active' : 'Upgrade to RedPDF PRO',
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/upgrade'),
        child: Container(
          padding: const EdgeInsets.all(3),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: isPremium
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            pdfTheme.gold.withValues(
                              alpha: isDark ? 0.25 : 0.2,
                            ),
                            pdfTheme.goldLight.withValues(
                              alpha: isDark ? 0.15 : 0.08,
                            ),
                          ],
                        )
                      : null,
                  color: isPremium
                      ? null
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPremium
                        ? pdfTheme.gold
                        : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    width: isPremium ? 1.8 : 1.2,
                  ),
                  boxShadow: isPremium
                      ? [
                          BoxShadow(
                            color: pdfTheme.gold.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Center(
                  child: Icon(
                    isPremium
                        ? Icons.workspace_premium_rounded
                        : Icons.workspace_premium_outlined,
                    color: isPremium ? pdfTheme.gold : const Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
              ),
              // Status indicator dot (Green = Active, Red = Inactive)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isPremium
                        ? const Color(0xFF10B981) // Green when active
                        : const Color(0xFFEF4444), // Red when inactive
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E2330) : Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isPremium
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444))
                                .withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return FittedBox(
      child: Row(
        spacing: 20,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RedPdf - Merge & Split',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Combine or split your PDF files with ease. ',
                style: Theme.of(context).textTheme.bodySmall,
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
      ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isSearching) ...[
          Container(
            height: 44,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pdfTheme.mergePrimary.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: pdfTheme.mergePrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search history files...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    tooltip: 'Clear',
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Close search',
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: _closeSearch,
                ),
              ],
            ),
          ),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  tabAlignment: TabAlignment.start,
                  isScrollable: true,
                  labelColor: pdfTheme.mergePrimary,
                  unselectedLabelColor: colorScheme.onSurface.withValues(
                    alpha: 0.5,
                  ),
                  indicatorColor: pdfTheme.mergePrimary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Merge History'),
                    Tab(text: 'Split History'),
                  ],
                  dividerColor: Colors.transparent,
                ),
              ),
            ),
            if (!_isSearching)
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Search history',
                splashRadius: 20,
                onPressed: () => setState(() => _isSearching = true),
              ),
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

  Widget _buildFileList(
    List<PdfFile> files,
    PdfThemeExtension pdfTheme, {
    bool isHistory = false,
  }) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No items in history.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: files.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
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
          margin: EdgeInsets.all(0),
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
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
                  await FileOpenerService.openPdf(context, path);
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
                    await pdfProv.deleteFile(file, fromHistory: isHistory);
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
                    FileOpenerService.openPdf(context, file.path!);
                  },
          ),
        );
      },
    );
  }
}
