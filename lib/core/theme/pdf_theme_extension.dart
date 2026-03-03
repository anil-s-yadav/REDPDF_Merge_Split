import 'package:flutter/material.dart';

class PdfThemeExtension extends ThemeExtension<PdfThemeExtension> {
  final Color mergePrimary;
  final Color mergeContainer;
  final Color splitPrimary;
  final Color splitContainer;
  final Color gold;
  final Color goldLight;

  const PdfThemeExtension({
    required this.mergePrimary,
    required this.mergeContainer,
    required this.splitPrimary,
    required this.splitContainer,
    required this.gold,
    required this.goldLight,
  });

  @override
  PdfThemeExtension copyWith({
    Color? mergePrimary,
    Color? mergeContainer,
    Color? splitPrimary,
    Color? splitContainer,
    Color? gold,
    Color? goldLight,
  }) {
    return PdfThemeExtension(
      mergePrimary: mergePrimary ?? this.mergePrimary,
      mergeContainer: mergeContainer ?? this.mergeContainer,
      splitPrimary: splitPrimary ?? this.splitPrimary,
      splitContainer: splitContainer ?? this.splitContainer,
      gold: gold ?? this.gold,
      goldLight: goldLight ?? this.goldLight,
    );
  }

  @override
  PdfThemeExtension lerp(ThemeExtension<PdfThemeExtension>? other, double t) {
    if (other is! PdfThemeExtension) return this;
    return PdfThemeExtension(
      mergePrimary: Color.lerp(mergePrimary, other.mergePrimary, t)!,
      mergeContainer: Color.lerp(mergeContainer, other.mergeContainer, t)!,
      splitPrimary: Color.lerp(splitPrimary, other.splitPrimary, t)!,
      splitContainer: Color.lerp(splitContainer, other.splitContainer, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldLight: Color.lerp(goldLight, other.goldLight, t)!,
    );
  }
}
