import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/pdf_theme_extension.dart';
import '../../providers/user_provider.dart';
import '../../services/billing_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'App Functions',
    'Payments',
    'Restore',
  ];

  final List<FaqItem> _faqList = const [
    // ── App Functions ────────────────────────────────────────────────────────
    FaqItem(
      category: 'App Functions',
      question: 'How do I merge multiple PDF files?',
      answer:
          '1. On the home screen, tap "Merge PDF".\n'
          '2. Select two or more PDF files from your device storage.\n'
          '3. Arrange their order by dragging the file items up or down.\n'
          '4. Tap "Merge PDFs" to generate your combined document instantly.',
      icon: Icons.call_merge_rounded,
    ),
    FaqItem(
      category: 'App Functions',
      question: 'How does PDF Split work?',
      answer:
          'Tap "Split PDF" and choose a document. You can split by:\n'
          '• Split All: Extracts every page into an individual PDF file.\n'
          '• Select Pages: Tap specific page thumbnails to extract only the ones you need.\n'
          '• Page Ranges: Enter ranges like "1-5, 8-10" to extract custom page blocks.',
      icon: Icons.call_split_rounded,
    ),
    FaqItem(
      category: 'App Functions',
      question: 'Where are my merged and split files saved?',
      answer:
          'All output files are saved directly in your phone\'s system "Downloads" directory '
          '(inside the RedPDF subfolder). You can open them from any file manager app, '
          'or tap on any entry in the Home screen history tab.',
      icon: Icons.folder_open_rounded,
    ),
    FaqItem(
      category: 'App Functions',
      question: 'Are my PDF documents private and secure?',
      answer:
          'Yes, 100%! RedPDF operates completely on-device. Your documents never leave '
          'your phone, and are never uploaded to any remote server or cloud. '
          'Your files remain completely private to you.',
      icon: Icons.security_rounded,
    ),

    // ── Payments & Subscriptions ─────────────────────────────────────────────
    FaqItem(
      category: 'Payments',
      question: 'How are payments processed?',
      answer:
          'All transactions are handled securely through Google Play Billing. '
          'You can pay using UPI (Google Pay, PhonePe, Paytm), Credit/Debit cards, '
          'Net Banking, or Google Play balance.',
      icon: Icons.credit_card_rounded,
    ),
    FaqItem(
      category: 'Payments',
      question: 'What subscription plans are available?',
      answer:
          'We offer 4 plans to fit your needs:\n'
          '• 1 Month: ₹29 / month\n'
          '• 6 Months: ₹99\n'
          '• 1 Year: ₹189 (Most Popular • Save 46%)\n'
          '• Lifetime Access: ₹999 (Best Value • Pay once, use forever)',
      icon: Icons.workspace_premium_rounded,
    ),
    FaqItem(
      category: 'Payments',
      question: 'Can I cancel my subscription anytime?',
      answer:
          'Yes. Subscriptions can be cancelled at any time with no penalties. '
          'Open Google Play Store → Profile icon (top-right) → Payments & subscriptions → '
          'Subscriptions → RedPDF → Cancel Subscription. You will keep PRO access until '
          'the end of your current billing period.',
      icon: Icons.cancel_outlined,
    ),

    // ── Restore Purchases ────────────────────────────────────────────────────
    FaqItem(
      category: 'Restore',
      question: 'How do I restore my purchase on a new phone?',
      answer:
          '1. Make sure you are logged into the same Google Play account you purchased with.\n'
          '2. Go to Settings → Upgrade to PRO (or use the button below) and tap "Restore Purchases".\n'
          '3. Google Play will verify your active subscription or lifetime license and immediately restore PRO access.',
      icon: Icons.restore_rounded,
    ),
    FaqItem(
      category: 'Restore',
      question: 'My purchase didn\'t restore automatically. What should I do?',
      answer:
          '• Ensure your device has an active internet connection.\n'
          '• Check in Google Play Store app that you are logged into the primary purchasing account.\n'
          '• If you still encounter issues, email us at anilyadav44x@gmail.com with your Google Play order GPA number.',
      icon: Icons.help_center_rounded,
    ),
  ];

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      query: _encodeQueryParameters(<String, String>{
        'subject': 'RedPDF App Support Request',
        'body':
            'Hi Anil,\n\n'
            'I have a question/issue regarding RedPDF:\n\n'
            '[Please describe your issue or question here]\n\n'
            'App Version: ${AppConstants.version}\n',
      }),
    );

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(emailUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      log('Could not launch email: $e');
      if (context.mounted) {
        _copyEmailToClipboard(context);
      }
    }
  }

  void _copyEmailToClipboard(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: AppConstants.supportEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Support email copied: ${AppConstants.supportEmail}'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final billing = context.watch<BillingService>();

    // Filter FAQs by category
    final filteredFaqs = _faqList.where((item) {
      return _selectedCategory == 'All' || item.category == _selectedCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FAQs & Help',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Category Filter Chips ──
              _buildCategoryChips(colorScheme, pdfTheme, isDark),
              const SizedBox(height: 20),

              // ── Restore Purchases Shortcut Banner ──
              if (_selectedCategory == 'All' ||
                  _selectedCategory == 'Restore') ...[
                _buildRestoreBanner(
                  context,
                  pdfTheme,
                  colorScheme,
                  isDark,
                  billing,
                ),
                const SizedBox(height: 20),
              ],

              // ── FAQ Accordion Section ──
              Text(
                'Frequently Asked Questions (${filteredFaqs.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),

              if (filteredFaqs.isEmpty)
                _buildEmptyState(colorScheme, isDark)
              else
                ...filteredFaqs.map(
                  (faq) => _buildFaqTile(
                    context,
                    faq,
                    pdfTheme,
                    colorScheme,
                    isDark,
                  ),
                ),

              const SizedBox(height: 24),

              // ── Contact Developer Card ──
              _buildContactDeveloperCard(
                context,
                pdfTheme,
                colorScheme,
                isDark,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(
    ColorScheme colorScheme,
    PdfThemeExtension pdfTheme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              selectedColor: pdfTheme.mergePrimary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12.5,
              ),
              backgroundColor: isDark
                  ? colorScheme.surface
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              side: BorderSide(
                color: isSelected
                    ? pdfTheme.mergePrimary
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRestoreBanner(
    BuildContext context,
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    bool isDark,
    BillingService billing,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restore_rounded,
              color: Color(0xFF3B82F6),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Already Bought PRO?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Restore your previous subscription or lifetime purchase on this device.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: billing.isPurchasing
                ? null
                : () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Checking Google Play for previous purchases...',
                        ),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    await billing.restorePurchases();
                    if (context.mounted) {
                      if (billing.purchaseError != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(billing.purchaseError!),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        final isPremium =
                            context.read<UserProvider>().isPremium;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isPremium
                                  ? 'PRO access restored successfully!'
                                  : 'No active purchases found for this Google account.',
                            ),
                            backgroundColor:
                                isPremium ? const Color(0xFF10B981) : null,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text('Restore', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(
    BuildContext context,
    FaqItem faq,
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.7)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: pdfTheme.mergePrimary.withValues(alpha: 0.1),
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: pdfTheme.mergeContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(faq.icon, color: pdfTheme.mergePrimary, size: 16),
            ),
            title: Text(
              faq.question,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                faq.answer,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No matching questions found',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try searching for different keywords or email our developer directly below.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDeveloperCard(
    BuildContext context,
    PdfThemeExtension pdfTheme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.8)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      pdfTheme.mergePrimary,
                      pdfTheme.mergePrimary.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Still need help or found a bug?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Direct support from the developer',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Email display row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    AppConstants.supportEmail,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Copy Email',
                  onPressed: () => _copyEmailToClipboard(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Email CTA button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _launchEmail(context),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text(
                'Send Email to Developer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: pdfTheme.mergePrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FaqItem {
  final String category;
  final String question;
  final String answer;
  final IconData icon;

  const FaqItem({
    required this.category,
    required this.question,
    required this.answer,
    required this.icon,
  });
}
