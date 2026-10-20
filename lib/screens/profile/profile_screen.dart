import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/ad_banner_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _launchUrl(AppConstants.developerStoreUrl),
          child: Row(
            children: [
              const Text(
                "A product by:  ",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              Image.asset(
                AppConstants.googlePlayIconAsset,
                height: 20,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.shop, size: 20, color: Colors.grey),
              ),
              const Text(
                " RedPDF",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing24,
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Remove Ads Tile (Clean outside tile) ──
              GestureDetector(
                onTap: () =>
                    _showRemoveAdsModal(context, pdfTheme, colorScheme, isDark),
                child: _buildSettingsItem(
                  context,
                  colorScheme,
                  isDark: isDark,
                  accentColor: const Color(0xFFF59E0B),
                  icon: Icons.block_flipped,
                  title: 'Remove Ads',
                  subtitle: 'Remove all ads & faster processing',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Colors.white, size: 14),
                        SizedBox(width: 3),
                        Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── App Theme ──
              _buildSettingsItem(
                context,
                colorScheme,
                isDark: isDark,
                accentColor: const Color(0xFF3B82F6),
                icon: Icons.brightness_6,
                title: 'App Theme',
                subtitle:
                    'Currently ${themeProvider.isDarkMode ? 'Dark' : 'Light'} Mode',
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (val) => themeProvider.toggleTheme(),
                ),
              ),

              // ── Privacy Policy ──
              GestureDetector(
                onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
                child: _buildSettingsItem(
                  context,
                  colorScheme,
                  isDark: isDark,
                  accentColor: const Color(0xFF10B981),
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),

              // ── Terms of Service ──
              GestureDetector(
                onTap: () => _launchUrl(AppConstants.termsOfServiceUrl),
                child: _buildSettingsItem(
                  context,
                  colorScheme,
                  isDark: isDark,
                  accentColor: const Color(0xFF06B6D4),
                  icon: Icons.gavel_rounded,
                  title: 'Terms of Service',
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),

              // ── Version Info ──
              _buildSettingsItem(
                context,
                colorScheme,
                isDark: isDark,
                accentColor: const Color(0xFF8B5CF6),
                icon: Icons.info_outline,
                title: 'Version Info',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF8B5CF6,
                    ).withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    AppConstants.version,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFC4B5FD)
                          : const Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              // ── Our Other Apps ──
              _buildOurOtherAppsCard(context, pdfTheme, colorScheme, isDark),
              const SizedBox(height: 8),

              // ── Rate Us Card (Same Design, Compact) ──
              _buildRatingCard(context, pdfTheme, colorScheme, isDark),
              const SizedBox(height: 16),

              // ── Bottom Banner Ad ──
              const Center(
                child: AdBannerWidget(
                  bannerType: AdBannerType.standard,
                  showBadge: true,
                ),
              ),
              const SizedBox(height: 80), // Padding for bottom floating navbar
            ],
          ),
        ),
      ),
    );
  }

  // ── Modal Bottom Sheet with the 3 Pricing Cards ──
  void _showRemoveAdsModal(
    BuildContext context,
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    int selectedIndex = 1; // Default to 5 Years (₹399)

    final plans = [
      {
        'title': '1 Year',
        'price': '₹99',
        'duration': '1 year',
        'desc': 'Remove all ads and faster processing for 1 year',
        'badge': '',
      },
      {
        'title': '5 Years',
        'price': '₹299',
        'duration': '5 years',
        'desc': 'Remove all ads and faster processing for 5 years',
        'badge': 'POPULAR',
      },
      {
        'title': 'Lifetime',
        'price': '₹799',
        'duration': 'lifetime',
        'desc': 'Remove all ads and faster processing for lifetime',
        'badge': 'BEST VALUE',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedPlan = plans[selectedIndex];
            final goldColor = pdfTheme.gold;

            return Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: 28,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2330) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with crown icon
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [goldColor, const Color(0xFFF59E0B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Remove Ads & Go PRO',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Choose your plan to remove ads and boost speed',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3 Pricing Cards
                  ...List.generate(plans.length, (index) {
                    final plan = plans[index];
                    final isSelected = selectedIndex == index;
                    final badge = plan['badge'] as String;

                    return GestureDetector(
                      onTap: () => setModalState(() => selectedIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                    ? goldColor.withValues(alpha: 0.15)
                                    : const Color(0xFFFFFBEB))
                              : (isDark
                                    ? const Color(0xFF282F40)
                                    : colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? goldColor
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.06)),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: goldColor.withValues(alpha: 0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isSelected ? goldColor : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        plan['title'] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? (isDark
                                                    ? Colors.white
                                                    : const Color(0xFF78350F))
                                              : null,
                                        ),
                                      ),
                                      if (badge.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: goldColor,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            badge,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    plan['desc'] as String,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              plan['price'] as String,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? goldColor : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Proceed CTA Button
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Selected ${selectedPlan['title']} for ${selectedPlan['price']}! Proceeding...',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [goldColor, const Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: goldColor.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Proceed with ${selectedPlan['price']} • ${selectedPlan['title']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Our Other Apps – Premium Indigo Gradient Card ──
  Widget _buildOurOtherAppsCard(
    BuildContext context,
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () => _launchUrl(AppConstants.developerStoreUrl),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1A1040),
                      const Color(0xFF0F2847),
                      const Color(0xFF0B1929),
                    ]
                  : [
                      const Color(0xFFEDE9FE),
                      const Color(0xFFDBEAFE),
                      const Color(0xFFE0E7FF),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                  : const Color(0xFF818CF8).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 237, 238, 250),
                      Color.fromARGB(255, 168, 170, 247),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  AppConstants.googlePlayIconAsset,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.shop, size: 20, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Our Other Apps',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF312E81),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'REDPDF',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "• More Tools from Redpdf",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFFA5B4FC)
                            : const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark
                    ? const Color(0xFFA5B4FC)
                    : const Color(0xFF6366F1),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    ColorScheme colorScheme, {
    required bool isDark,
    required Color accentColor,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.7)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: accentColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  // ── Rate Us – Premium Amber/Gold Gradient Card (Original Design, Made Compact) ──
  Widget _buildRatingCard(
    BuildContext context,
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final amberPrimary = isDark
        ? const Color(0xFFFBBF24)
        : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: () => _launchUrl(AppConstants.playStoreUrl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1C1508),
                    const Color(0xFF1A1204),
                    const Color(0xFF171002),
                  ]
                : [
                    const Color(0xFFFFFBEB),
                    const Color(0xFFFEF3C7),
                    const Color(0xFFFDE68A).withValues(alpha: 0.4),
                  ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: amberPrimary.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: amberPrimary.withValues(alpha: isDark ? 0.1 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Five-star row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Icon(
                    Icons.star_rounded,
                    color: amberPrimary,
                    size: 22,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoying RedPDF?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF78350F),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Your review helps us improve and reach more users!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFFFCD34D).withValues(alpha: 0.7)
                    : const Color(0xFF92400E).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            // Full-width CTA button with glow
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFFF59E0B), const Color(0xFFEAB308)]
                      : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: amberPrimary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _launchUrl(AppConstants.playStoreUrl),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Rate Us on Play Store',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
