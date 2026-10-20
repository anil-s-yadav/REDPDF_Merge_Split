import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/ad_banner_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        log('Could not launch $url: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final isPremium = userProvider.isPremium;
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
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/upgrade'),
                child: _buildSettingsItem(
                  context,
                  colorScheme,
                  isDark: isDark,
                  accentColor: isPremium
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  icon: Icons.workspace_premium_rounded,
                  title: isPremium ? 'RedPDF PRO Active' : 'Upgrade to RedPDF PRO',
                  subtitle: isPremium
                      ? 'Ad-free experience & unlimited processing'
                      : 'Remove all ads • Faster processing • From ₹29',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPremium
                            ? const [Color(0xFF10B981), Color(0xFF059669)]
                            : const [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (isPremium
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B))
                              .withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPremium ? Icons.check_circle_rounded : Icons.bolt,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPremium ? 'ACTIVE' : '₹29 / mo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.4,
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
