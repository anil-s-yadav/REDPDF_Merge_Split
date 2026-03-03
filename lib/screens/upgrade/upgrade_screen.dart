import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/user_provider.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final userProvider = context.read<UserProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.2,
            colors: [pdfTheme.gold.withValues(alpha: 0.15), colorScheme.surface],
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
                      const SizedBox(height: 20),
                      _buildHeaderIcon(pdfTheme),
                      const SizedBox(height: 32),
                      const Text(
                        'Get All Features',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Experience the full power of our\nprofessional PDF toolkit without limits.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                      const SizedBox(height: 40),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.layers_outlined,
                        'Unlimited PDF Merges & Splits',
                      ),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.cloud_done_outlined,
                        'Secure Cloud Processing',
                      ),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.block_flipped,
                        'No Advertisements',
                      ),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.headset_mic_outlined,
                        'Priority Support',
                      ),
                      _buildFeatureItem(
                        pdfTheme,
                        Icons.drive_file_rename_outline,
                        'Custom File Naming',
                      ),
                      const SizedBox(height: 32),
                      _buildLimitBox(colorScheme),
                      const SizedBox(height: 48),
                      _buildPricingOptions(pdfTheme, colorScheme),
                      const SizedBox(height: 32),
                      _buildUnlockButton(context, pdfTheme, userProvider),
                      const SizedBox(height: 40),
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
      padding: const EdgeInsets.all(AppConstants.spacing24),
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
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: pdfTheme.gold.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: pdfTheme.gold.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: pdfTheme.gold,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.stars, color: Colors.white, size: 50),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: pdfTheme.mergeContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: pdfTheme.mergePrimary, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitBox(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: const Column(
        children: [
          Text(
            'Free Plan Limits: 3 merges per day & 5MB max file size.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          SizedBox(height: 4),
          Text(
            'Upgrade for unlimited access.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOptions(
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MONTHLY',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹99',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Text(
                      ' /month',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: pdfTheme.mergePrimary, width: 2),
                  color: pdfTheme.mergeContainer.withValues(alpha: 0.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YEARLY',
                      style: TextStyle(
                        color: pdfTheme.mergePrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹399',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const Text(
                          ' /year',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -12,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pdfTheme.mergePrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '60% OFF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockButton(
    BuildContext context,
    PdfThemeExtension pdfTheme,
    UserProvider userProvider,
  ) {
    return InkWell(
      onTap: () {
        userProvider.togglePremium();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium Unlocked Successfully!')),
        );
      },
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(colors: [pdfTheme.gold, pdfTheme.goldLight]),
          boxShadow: [
            BoxShadow(
              color: pdfTheme.gold.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Unlock Premium Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.bolt, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    final style = TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.5),
      fontSize: 12,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text('Restore\nPurchase', textAlign: TextAlign.center, style: style),
        Text('Terms of\nUse', textAlign: TextAlign.center, style: style),
        Text('Privacy\nPolicy', textAlign: TextAlign.center, style: style),
      ],
    );
  }
}
