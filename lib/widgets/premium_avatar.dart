import 'dart:developer';

import 'package:flutter/material.dart';
import '../core/theme/pdf_theme_extension.dart';

class PremiumAvatar extends StatelessWidget {
  final String imageUrl;
  final bool isPremium;
  final double size;

  const PremiumAvatar({
    super.key,
    required this.imageUrl,
    this.isPremium = false,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final pdfTheme = Theme.of(context).extension<PdfThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;
    log(imageUrl);
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isPremium
                ? LinearGradient(colors: [pdfTheme.gold, pdfTheme.goldLight])
                : null,
            color: isPremium
                ? null
                : colorScheme.outline.withValues(alpha: 0.5),
            boxShadow: [
              if (isPremium)
                BoxShadow(
                  color: pdfTheme.gold.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.green.shade900,
            child: ClipOval(
              child: Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, size: size * 0.5);
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const CircularProgressIndicator(strokeWidth: 2);
                },
              ),
            ),
          ),
        ),
        if (isPremium)
          Positioned(
            right: 30,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: pdfTheme.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
  }
}
