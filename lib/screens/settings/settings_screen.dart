import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        children: [
          _buildSectionHeader(pdfTheme, 'GENERAL'),
          _buildSettingsTile(
            colorScheme,
            pdfTheme,
            icon: Icons.folder_open,
            title: 'Default Save Location',
            subtitle: '/Documents/PDF_Utility',
            trailing: const Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            colorScheme,
            pdfTheme,
            icon: Icons.edit_note,
            title: 'File Naming Format',
            subtitle: 'YYYY-MM-DD_Name',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: pdfTheme.mergeContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Edit',
                style: TextStyle(
                  color: pdfTheme.mergePrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(pdfTheme, 'NOTIFICATIONS'),
          _buildSettingsTile(
            colorScheme,
            pdfTheme,
            icon: Icons.notifications_none,
            title: 'Push Notifications',
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeThumbColor: pdfTheme.mergePrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            colorScheme,
            pdfTheme,
            icon: Icons.email_outlined,
            title: 'Email Alerts',
            trailing: Switch(value: false, onChanged: (v) {}),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(pdfTheme, 'SUPPORT & ABOUT'),
          _buildSettingsTile(
            colorScheme,
            pdfTheme,
            icon: Icons.star_border,
            title: 'Rate App',
            trailing: const Icon(Icons.link, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            colorScheme,
            pdfTheme,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            trailing: const Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            colorScheme,
            pdfTheme,
            icon: Icons.info_outline,
            title: 'Version Info',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          const SizedBox(height: 48),
          _buildBranding(pdfTheme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(PdfThemeExtension pdfTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: pdfTheme.mergePrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    ColorScheme colorScheme,
    PdfThemeExtension pdfTheme, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: pdfTheme.mergeContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: pdfTheme.mergePrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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

  Widget _buildBranding(PdfThemeExtension pdfTheme, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: pdfTheme.mergePrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'PDF Utility',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'PROUDLY MADE FOR EFFICIENCY',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
