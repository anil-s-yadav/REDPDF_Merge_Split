import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pdf_theme_extension.dart';

class AppTheme {
  // Brand Colors (from requirements)
  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightText = Color(0xFF111827);
  static const Color _lightSecondaryText = Color(0xFF6B7280);
  static const Color _lightBorder = Color(0xFFE5E7EB);

  // Better Dark Theme Palette
  static const Color _darkBg = Color(0xFF0B0F19);
  static const Color _darkSurface = Color(0xFF111827);
  static const Color _darkText = Color(0xFFF9FAFB);
  static const Color _darkSecondaryText = Color(0xFF9CA3AF);
  static const Color _darkBorder = Color(0xFF1F2937);

  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF16A34A), // Default to Merge Green
        onPrimary: Colors.white,
        surface: _lightSurface,
        onSurface: _lightText,
        outline: _lightBorder,
      ),
      scaffoldBackgroundColor: _lightBg,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        titleLarge: GoogleFonts.inter(
          color: _lightText,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.inter(color: _lightText),
        bodyMedium: GoogleFonts.inter(color: _lightSecondaryText),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBg,
        foregroundColor: _lightText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: _lightText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightBorder),
        ),
      ),
      extensions: const [
        PdfThemeExtension(
          mergePrimary: Color(0xFF16A34A),
          mergeContainer: Color(0xFFDCFCE7),
          splitPrimary: Color(0xFFDC2626),
          splitContainer: Color(0xFFFEE2E2),
          gold: Color(0xFFEAB308),
          goldLight: Color(0xFFFACC15),
        ),
      ],
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF22C55E),
        onPrimary: Colors.white,
        surface: _darkSurface,
        onSurface: _darkText,
        outline: _darkBorder,
      ),
      scaffoldBackgroundColor: _darkBg,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        titleLarge: GoogleFonts.inter(
          color: _darkText,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.inter(color: _darkText),
        bodyMedium: GoogleFonts.inter(color: _darkSecondaryText),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBg,
        foregroundColor: _darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: _darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkBorder),
        ),
      ),
      extensions: const [
        PdfThemeExtension(
          mergePrimary: Color(0xFF22C55E),
          mergeContainer: Color(0xFF052E16),
          splitPrimary: Color(0xFFF43F5E),
          splitContainer: Color(0xFF3F0D14),
          gold: Color(0xFFFACC15),
          goldLight: Color(0xFFFDE68A),
        ),
      ],
    );
  }
}
