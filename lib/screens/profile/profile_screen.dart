import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
// import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    // final userProvider = context.watch<UserProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _launchUrl(
            "https://play.google.com/store/apps/dev?id=8832237281097064209",
          ),
          child: Row(
            children: [
              Text(
                "A product by:  ",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              // Icon(Icons.picture_as_pdf, color: color.danger),
              Image.asset("lib/assets/google-play-store-icon.png", height: 20),
              // const SizedBox(width: 8),
              Text(
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

              GestureDetector(
                onTap: () => _launchUrl(
                  "https://anil-s-yadav.github.io/REDPDF-PrivacyPolicy/",
                ),
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

              _buildOurOtherAppsCard(context, pdfTheme, colorScheme, isDark),
              const SizedBox(height: 8),
              _buildRatingCard(context, pdfTheme, colorScheme, isDark),
              const SizedBox(height: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: () => _launchUrl(
          "https://play.google.com/store/apps/dev?id=8832237281097064209",
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                  : const Color(0xFF818CF8).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF6366F1,
                ).withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Gradient icon container
              Container(
                width: 52,
                height: 52,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 237, 238, 250),
                      Color.fromARGB(255, 168, 170, 247),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  "lib/assets/google-play-store-icon.png",
                  // height: 1s0,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          'Our Other Apps',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF312E81),
                          ),
                        ),
                        Text(
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
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFFA5B4FC)
                            : const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                      : const Color(0xFF6366F1).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: isDark
                      ? const Color(0xFFA5B4FC)
                      : const Color(0xFF6366F1),
                  size: 20,
                ),
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
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.7)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.15 : 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accentColor, size: 22),
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
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: accentColor.withValues(alpha: 0.7),
                      fontSize: 13,
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

  // ── Rate Us – Premium Amber/Gold Gradient Card ──
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
      onTap: () => _launchUrl(
        'https://play.google.com/store/apps/details?id=com.legendarysoftware.marge_pdf_split_pdf',
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: amberPrimary.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: amberPrimary.withValues(alpha: isDark ? 0.1 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    Icons.star_rounded,
                    color: amberPrimary,
                    size: 28,
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            Text(
              'Enjoying RedPDF?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF78350F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your review helps us improve and reach more users!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFFFCD34D).withValues(alpha: 0.7)
                    : const Color(0xFF92400E).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            // Full-width CTA button with glow
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFFF59E0B), const Color(0xFFEAB308)]
                      : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: amberPrimary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _launchUrl(
                    'https://play.google.com/store/apps/details?id=com.legendarysoftware.marge_pdf_split_pdf',
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Rate Us on Play Store',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
