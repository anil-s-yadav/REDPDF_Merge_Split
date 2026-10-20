import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/user_provider.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  int _selectedPlanIndex = 1; // 0: 1 Year, 1: 5 Years, 2: Lifetime

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final userProvider = context.read<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.2,
            colors: [
              pdfTheme.gold.withValues(alpha: 0.15),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacing24,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildHeaderIcon(pdfTheme),
                      const SizedBox(height: 24),
                      const Text(
                        'Unlock RedPDF PRO',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Experience unlimited, ad-free PDF productivity with accelerated file processing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.block_flipped,
                        '100% Ad-Free Experience (No Banners & No Ads)',
                      ),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.bolt_rounded,
                        'Turbo File Processing (Faster Merge & Split)',
                      ),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.all_inclusive_rounded,
                        'Unlimited PDF Operations & No File Size Caps',
                      ),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.security_rounded,
                        'Local & Secure On-Device Processing',
                      ),
                      const SizedBox(height: 28),
                      _buildPricingCards(pdfTheme, colorScheme, isDark),
                      const SizedBox(height: 28),
                      _buildUnlockButton(context, pdfTheme, userProvider),
                      const SizedBox(height: 24),
                      _buildFooter(colorScheme),
                      const SizedBox(height: 20),
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing20,
        vertical: AppConstants.spacing12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Upgrade to Premium',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(PdfThemeExtension pdfTheme) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: pdfTheme.gold.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: pdfTheme.gold.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: pdfTheme.gold,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    PdfThemeExtension pdfTheme,
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: pdfTheme.mergeContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: pdfTheme.mergePrimary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards(
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final plans = [
      {
        'title': '1 Year',
        'price': '₹99',
        'duration': 'for 1 year',
        'badge': '',
      },
      {
        'title': '5 Years',
        'price': '₹399',
        'duration': 'for 5 years',
        'badge': 'POPULAR',
      },
      {
        'title': 'Lifetime',
        'price': '₹999',
        'duration': 'forever',
        'badge': 'BEST VALUE',
      },
    ];

    return Column(
      children: List.generate(plans.length, (index) {
        final plan = plans[index];
        final isSelected = _selectedPlanIndex == index;
        final hasBadge = (plan['badge'] as String).isNotEmpty;

        return GestureDetector(
          onTap: () => setState(() => _selectedPlanIndex = index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? pdfTheme.gold.withValues(alpha: 0.15)
                      : const Color(0xFFFFFBEB))
                  : (isDark
                      ? colorScheme.surface.withValues(alpha: 0.8)
                      : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? pdfTheme.gold
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: pdfTheme.gold.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
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
                  color: isSelected ? pdfTheme.gold : Colors.grey,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan['title'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF78350F))
                                  : null,
                            ),
                          ),
                          if (hasBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: pdfTheme.gold,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                plan['badge'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Remove all ads & faster processing ${plan['duration']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  plan['price'] as String,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? pdfTheme.gold : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildUnlockButton(
    BuildContext context,
    PdfThemeExtension pdfTheme,
    UserProvider userProvider,
  ) {
    final prices = ['₹99', '₹399', '₹999'];
    final selectedPrice = prices[_selectedPlanIndex];

    return InkWell(
      onTap: () {
        userProvider.togglePremium();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PRO Unlocked for $selectedPrice! (Demo)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(colors: [pdfTheme.gold, pdfTheme.goldLight]),
          boxShadow: [
            BoxShadow(
              color: pdfTheme.gold.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Get PRO for $selectedPrice',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    final style = TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.6),
      fontSize: 12,
      decoration: TextDecoration.underline,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () => _launchUrl(AppConstants.termsOfServiceUrl),
          child: Text('Terms of Service', textAlign: TextAlign.center, style: style),
        ),
        GestureDetector(
          onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
          child: Text('Privacy Policy', textAlign: TextAlign.center, style: style),
        ),
      ],
    );
  }
}
