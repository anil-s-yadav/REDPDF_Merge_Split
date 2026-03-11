import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/user_provider.dart';
import '../../providers/pdf_provider.dart';
import '../../widgets/premium_avatar.dart';
import '../../widgets/action_pill.dart';

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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      pdfProvider.history
                          .where(
                            (f) => f.name.toLowerCase().contains(
                              _searchController.text.toLowerCase(),
                            ),
                          )
                          .toList(),
                      pdfTheme,
                    ),
                    _buildFileList([], pdfTheme),
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
              'Convert PDF - all tools',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Select any document or image to get\nstarted',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/upgrade'),
          child: PremiumAvatar(
            imageUrl: 'https://ui-avatars.com/api/?name=User',
            isPremium: user.isPremium,
            size: 50,
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
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: pdfTheme.mergePrimary,
              unselectedLabelColor: colorScheme.onSurface.withValues(
                alpha: 0.5,
              ),
              indicatorColor: pdfTheme.mergePrimary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [
                Tab(text: 'History'),
                Tab(text: 'All Files'),
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
              context.read<PdfProvider>().clearHistory();
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

  Widget _buildFileList(List<PdfFile> files, PdfThemeExtension pdfTheme) {
    if (files.isEmpty) {
      return Center(
        child: Text(
          'No files yet',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
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
            trailing: const Icon(Icons.more_vert),
            onTap: () {},
          ),
        );
      },
    );
  }
}
