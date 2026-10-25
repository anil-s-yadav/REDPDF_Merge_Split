import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/user_provider.dart';
import '../../services/billing_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  // 0: 1 Month (₹29), 1: 6 Months (₹99), 2: 1 Year (₹189), 3: Lifetime (₹999)
  int _selectedPlanIndex = 2; // Default to 1 Year (Most Popular)

  final List<Map<String, dynamic>> _plans = const [
    {
      'id': BillingService.idMonth1,
      'title': '1 Month',
      'price': '₹29',
      'originalPrice': '',
      'period': '/ month',
      'desc': 'Remove ads & faster processing for 1 month',
      'badge': '',
    },
    {
      'id': BillingService.idMonths6,
      'title': '6 Months',
      'price': '₹99',
      'originalPrice': '₹174',
      'period': 'for 6 months',
      'desc': '₹16.5/mo • Save 43% compared to monthly',
      'badge': '',
    },
    {
      'id': BillingService.idYear1,
      'title': '1 Year',
      'price': '₹189',
      'originalPrice': '₹348',
      'period': 'for 1 year',
      'desc': '₹15.7/mo • Save 46% compared to monthly',
      'badge': 'MOST POPULAR',
    },
    {
      'id': BillingService.idLifetime,
      'title': 'Lifetime',
      'price': '₹999',
      'originalPrice': '₹1,999',
      'period': 'one-time',
      'desc': 'Pay once, keep PRO features forever',
      'badge': 'BEST VALUE',
    },
  ];

  String _getOriginalPrice(
    Map<String, dynamic> plan,
    BillingService billingService,
  ) {
    final original = plan['originalPrice'] as String? ?? '';
    if (original.isEmpty) return '';

    final month1Product = billingService.getProduct(BillingService.idMonth1);
    if (month1Product != null && month1Product.rawPrice > 0) {
      final symbol = month1Product.currencySymbol.isNotEmpty
          ? month1Product.currencySymbol
          : '₹';
      final planId = plan['id'] as String;
      if (planId == BillingService.idMonths6) {
        final total = month1Product.rawPrice * 6;
        return '$symbol${total.toStringAsFixed(total % 1 == 0 ? 0 : 2)}';
      } else if (planId == BillingService.idYear1) {
        final total = month1Product.rawPrice * 12;
        return '$symbol${total.toStringAsFixed(total % 1 == 0 ? 0 : 2)}';
      }
    }
    return original;
  }

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
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final userProvider = context.watch<UserProvider>();
    final billingService = context.watch<BillingService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.3,
            colors: [
              pdfTheme.gold.withValues(alpha: 0.16),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar with "X" Close in Top-Right ──
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacing24,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      _buildHeaderIcon(pdfTheme),
                      const SizedBox(height: 18),
                      const Text(
                        'Unlock RedPDF PRO',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enjoy completely ad-free workflows and faster file processing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 22),

                      if (userProvider.isPremium) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'RedPDF PRO is Active',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── Feature Highlights ──
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.block_flipped,
                        '100% Ad-Free Experience',
                        'No banner ads or interruptions across the app',
                      ),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.bolt_rounded,
                        'Faster Processing Speed',
                        'Accelerated PDF merging and splitting operations',
                      ),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.all_inclusive_rounded,
                        'Unlimited PDF Operations',
                        'Merge and split as many documents as you need',
                      ),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.security_rounded,
                        '100% Private On-Device',
                        'Files never leave your phone or upload to servers',
                      ),
                      const SizedBox(height: 20),

                      // ── 4 Pricing Cards (Live Google Play Prices) ──
                      _buildPricingCards(
                        pdfTheme,
                        colorScheme,
                        isDark,
                        billingService,
                      ),
                      const SizedBox(height: 24),

                      // ── CTA Continue / Buy Button ──
                      _buildContinueButton(
                        context,
                        pdfTheme,
                        userProvider,
                        billingService,
                      ),
                      const SizedBox(height: 12),

                      // ── Restore Purchases ──
                      _buildRestoreButton(context, billingService),
                      const SizedBox(height: 12),

                      // ── Footer Links ──
                      _buildFooter(colorScheme),
                      const SizedBox(height: 16),
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

  // ── Top Bar with "X" Close Button in Top-Right ──
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFEAB308),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'RedPDF PRO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 26),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(PdfThemeExtension pdfTheme) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: pdfTheme.gold.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: pdfTheme.gold.withValues(alpha: 0.28),
            blurRadius: 26,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: pdfTheme.gold,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    PdfThemeExtension pdfTheme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: pdfTheme.mergeContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: pdfTheme.mergePrimary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                ),
              ],
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
    BillingService billingService,
  ) {
    return Column(
      children: List.generate(_plans.length, (index) {
        final plan = _plans[index];
        final planId = plan['id'] as String;
        final isSelected = _selectedPlanIndex == index;
        final badge = (plan['badge'] as String);
        final hasBadge = badge.isNotEmpty;

        // Fetch live localized price from Google Play if available
        final liveProduct = billingService.getProduct(planId);
        final displayPrice = liveProduct?.price ?? (plan['price'] as String);
        final originalPrice = _getOriginalPrice(plan, billingService);

        return GestureDetector(
          onTap: () => setState(() => _selectedPlanIndex = index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                        ? pdfTheme.gold.withValues(alpha: 0.16)
                        : const Color(0xFFFFFBEB))
                  : (isDark
                        ? colorScheme.surface.withValues(alpha: 0.8)
                        : colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.45,
                          )),
              borderRadius: BorderRadius.circular(15),
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
                        color: pdfTheme.gold.withValues(alpha: 0.22),
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
                  color: isSelected ? pdfTheme.gold : Colors.grey,
                  size: 20,
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
                          if (hasBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badge == 'BEST VALUE'
                                    ? const Color(0xFF10B981)
                                    : pdfTheme.gold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
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
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (originalPrice.isNotEmpty) ...[
                          Text(
                            originalPrice,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: isDark
                                  ? Colors.redAccent.shade100
                                  : Colors.red.shade400,
                              decorationThickness: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          displayPrice,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? pdfTheme.gold : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      plan['period'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContinueButton(
    BuildContext context,
    PdfThemeExtension pdfTheme,
    UserProvider userProvider,
    BillingService billingService,
  ) {
    final selected = _plans[_selectedPlanIndex];
    final productId = selected['id'] as String;
    final liveProduct = billingService.getProduct(productId);
    final displayPrice = liveProduct?.price ?? (selected['price'] as String);

    final bool isCurrentPlanActive =
        userProvider.isPremium && (userProvider.activePlanId == productId);

    final buttonLabel = isCurrentPlanActive
        ? 'Current Plan Active'
        : selected['title'] == 'Lifetime'
        ? 'Get Lifetime Access • $displayPrice'
        : 'Continue • $displayPrice ${selected['period']}';

    final isBusy = billingService.isPurchasing;

    return InkWell(
      onTap: isBusy || isCurrentPlanActive
          ? null
          : () async {
              final started = await billingService.buyProduct(productId);
              if (!started &&
                  billingService.purchaseError != null &&
                  context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(billingService.purchaseError!),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: isCurrentPlanActive
                ? const [Color(0xFF10B981), Color(0xFF059669)]
                : [pdfTheme.gold, pdfTheme.goldLight],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isCurrentPlanActive
                          ? const Color(0xFF10B981)
                          : pdfTheme.gold)
                      .withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: isBusy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isCurrentPlanActive
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton(
    BuildContext context,
    BillingService billingService,
  ) {
    return TextButton.icon(
      onPressed: billingService.isPurchasing
          ? null
          : () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checking for previous purchases...'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              await billingService.restorePurchases();
              if (context.mounted) {
                if (billingService.purchaseError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(billingService.purchaseError!),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  final isPremium = context.read<UserProvider>().isPremium;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isPremium
                            ? 'PRO access restored successfully!'
                            : 'No active purchases found for this Google account.',
                      ),
                      backgroundColor: isPremium ? const Color(0xFF10B981) : null,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
      icon: const Icon(Icons.restore_rounded, size: 16),
      label: const Text(
        'Restore Purchases',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    final style = TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.6),
      fontSize: 11.5,
      decoration: TextDecoration.underline,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () => _launchUrl(AppConstants.termsOfServiceUrl),
          child: Text(
            'Terms of Service',
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
        GestureDetector(
          onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
          child: Text(
            'Privacy Policy',
            textAlign: TextAlign.center,
            style: style,
          ),
        ),
      ],
    );
  }
}
