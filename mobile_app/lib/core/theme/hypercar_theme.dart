// ponytail: Centralized theme definitions keeping styling unified without deep cascades.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HypercarColors {
  // Base Obsidian & Carbon Surfaces
  static const Color obsidianBg = Color(0xFF070709);
  static const Color carbonSurface = Color(0xFF111216);
  static const Color carbonBorder = Color(0xFF22242C);
  static const Color carbonElevated = Color(0xFF181A20);

  // Danger & Tax Accents
  static const Color solarOrange = Color(0xFFFF5500); // Solar Hyper-Orange
  static const Color laserRed = Color(0xFFFF2A54);    // Laser Red / Crimson
  static const Color amberWarning = Color(0xFFFFB800);

  // Safe & Disciplined Accents
  static const Color cyberCyan = Color(0xFF00F0FF);   // Cyber Cyan
  static const Color matrixGreen = Color(0xFF10B981); // Matrix Green

  // Text & Neutrals (WCAG AA compliant)
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Thermal Receipt Skins
  static const Color receiptMattePaper = Color(0xFFF4F4F0);
  static const Color receiptMatteInk = Color(0xFF09090B);
  static const Color receiptStealthPaper = Color(0xFF121318);
  static const Color receiptStealthInk = Color(0xFFE2E8F0);
}

class HypercarTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HypercarColors.obsidianBg,
      primaryColor: HypercarColors.solarOrange,
      colorScheme: const ColorScheme.dark(
        primary: HypercarColors.solarOrange,
        secondary: HypercarColors.cyberCyan,
        surface: HypercarColors.carbonSurface,
        error: HypercarColors.laserRed,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: HypercarColors.textPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: HypercarColors.carbonSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: HypercarColors.carbonBorder, width: 1),
        ),
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: HypercarColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          color: HypercarColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          color: HypercarColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: HypercarColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          color: HypercarColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          color: HypercarColors.textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HypercarColors.solarOrange,
          foregroundColor: Colors.black,
          minimumSize: const Size(88, 48), // WCAG AA minimum tap target >= 44px
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HypercarColors.cyberCyan,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: HypercarColors.cyberCyan, width: 1.5),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HypercarColors.carbonElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HypercarColors.carbonBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HypercarColors.carbonBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HypercarColors.solarOrange, width: 1.5),
        ),
        hintStyle: GoogleFonts.spaceGrotesk(color: HypercarColors.textMuted),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: HypercarColors.carbonSurface,
        selectedItemColor: HypercarColors.solarOrange,
        unselectedItemColor: HypercarColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // JetBrains Mono text styles for receipts and telemetry
  static TextStyle monoStyle({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? HypercarColors.textPrimary,
      letterSpacing: letterSpacing,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
