import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
// import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/pdf_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final userProvider = context.watch<UserProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final pdfProvider = context.watch<PdfProvider>();
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      //   title: const Text('Profile'),
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing24,
          ),
          child: Column(
            children: [
              // const SizedBox(height: 16),
              // ListTile(
              //   leading: PremiumAvatar(
              //     imageUrl: 'https://ui-avatars.com/api/?name=User',
              //     isPremium: userProvider.isPremium,
              //   ),
              //   title: Text(
              //     userProvider.name,
              //     style: const TextStyle(
              //       fontSize: 24,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              //   subtitle: Text(
              //     userProvider.email,
              //     style: TextStyle(
              //       color: colorScheme.onSurface.withValues(alpha: 0.6),
              //     ),
              //   ),
              // ),

              // const SizedBox(height: 35),
              // _buildUpgradeCard(pdfTheme),
              const SizedBox(height: 30),
              _buildSettingsItem(
                context,
                colorScheme,
                icon: Icons.brightness_6,
                title: 'App Theme',
                subtitle:
                    'Currently ${themeProvider.isDarkMode ? 'Dark' : 'Light'} Mode',
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (val) => themeProvider.toggleTheme(),
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsItem(
                context,
                colorScheme,
                icon: Icons.visibility_off_outlined,
                title: 'Show Hidden & Deleted pdf',
                subtitle: 'Show deleted and hidden pdf files.',
                trailing: Switch(
                  value: pdfProvider.showHiddenFiles,
                  onChanged: (val) => pdfProvider.toggleShowHiddenFiles(),
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsItem(
                context,
                colorScheme,
                icon: Icons.grid_view_rounded,
                title: 'Our Other Apps',
                trailing: const Icon(Icons.chevron_right),
              ),

              // const SizedBox(height: 120),
              _buildSettingsItem(
                context,
                colorScheme,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                trailing: const Icon(Icons.chevron_right),
              ),
              // const SizedBox(height: 12),
              _buildSettingsItem(
                context,
                colorScheme,
                icon: Icons.info_outline,
                title: 'Version Info',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppConstants.version,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildRatingCard(pdfTheme, colorScheme),
              const SizedBox(height: 16),

              // const SizedBox(height: 40),
              // TextButton.icon(
              //   onPressed: () {},
              //   icon: const Icon(Icons.logout, color: Colors.red),
              //   label: const Text(
              //     'Logout',
              //     style: TextStyle(
              //       color: Colors.red,
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildUpgradeCard(PdfThemeExtension pdfTheme) {
  //   return Container(
  //     padding: const EdgeInsets.all(AppConstants.spacing16),
  //     decoration: BoxDecoration(
  //       color: pdfTheme.goldLight.withAlpha(30),
  //       borderRadius: BorderRadius.circular(AppConstants.borderRadius24),
  //       border: Border.all(color: pdfTheme.gold.withValues(alpha: 0.3)),
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Upgrade to Family Plan',
  //                 style: TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 18,
  //                   color: pdfTheme.gold,
  //                 ),
  //               ),
  //               Text(
  //                 'Share premium features with up to 5 members',
  //                 style: TextStyle(
  //                   color: pdfTheme.gold.withValues(alpha: 2),
  //                   fontSize: 13,
  //                 ),
  //               ),

  //               const SizedBox(height: 10),
  //               Container(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 12,
  //                   vertical: 6,
  //                 ),
  //                 decoration: BoxDecoration(
  //                   color: pdfTheme.gold,
  //                   borderRadius: BorderRadius.circular(30),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: pdfTheme.gold.withValues(alpha: 0.3),
  //                       blurRadius: 10,
  //                       offset: const Offset(0, 4),
  //                     ),
  //                   ],
  //                 ),
  //                 child: const Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(Icons.stars, color: Colors.white, size: 20),
  //                     SizedBox(width: 8),
  //                     Text(
  //                       'PREMIUM PLAN',
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               // ElevatedButton(
  //   onPressed: () {},
  //   style: ElevatedButton.styleFrom(
  //     backgroundColor: pdfTheme.gold,
  //     foregroundColor: Colors.white,
  //     minimumSize: const Size(double.infinity, 40),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //   ),
  //   child: const Text(
  //     'Get premium',
  //     style: TextStyle(fontWeight: FontWeight.bold),
  //   ),
  //               // ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(width: 16),
  //         Icon(Icons.group_add, size: 30, color: pdfTheme.gold),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSettingsItem(
    BuildContext context,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          // const SizedBox(width: 16),
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
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
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

  Widget _buildRatingCard(PdfThemeExtension pdfTheme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pdfTheme.mergeContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pdfTheme.mergePrimary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pdfTheme.mergePrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enjoying PDF Master?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rate us on the store',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: pdfTheme.mergePrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Rate Us'),
          ),
        ],
      ),
    );
  }
}
