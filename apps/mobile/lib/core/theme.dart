import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidade Ludmila & Dyego — cores extraídas da logo (ouro #B7975E).
class AppColors {
  static const primary = Color(0xFFB7975E);
  static const primaryDark = Color(0xFFA58751);
  static const accent = Color(0xFFC5A059);
  static const bgTop = Color(0xFFFFFEFB);
  static const bgBottom = Color(0xFFF7F1E6);
  static const ink = Color(0xFF2F2A24);
  static const muted = Color(0xFF8A8175);
  static const surface = Color(0xFFFFFCF8);
  static const surfaceElevated = Color(0xFFF5EEE4);
  static const danger = Color(0xFFB84A4A);
  static const warning = Color(0xFFC4892A);
  static const success = Color(0xFF6B8F71);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      brightness: Brightness.light,
    ),
  );

  final display = GoogleFonts.cormorantGaramondTextTheme(base.textTheme);
  final body = GoogleFonts.latoTextTheme(base.textTheme);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgBottom,
    canvasColor: AppColors.bgBottom,
    cardColor: AppColors.surface,
    dividerColor: AppColors.primary.withValues(alpha: 0.18),
    textTheme: body.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w500,
      ),
      displayMedium: display.displayMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w500,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w500,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: body.titleLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: AppColors.ink),
      bodyMedium: body.bodyMedium?.copyWith(color: AppColors.ink),
      bodySmall: body.bodySmall?.copyWith(color: AppColors.muted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.ink,
      titleTextStyle: GoogleFonts.cormorantGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryDark,
      ),
      iconTheme: const IconThemeData(color: AppColors.primaryDark),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primaryDark),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceElevated,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: const TextStyle(color: AppColors.ink),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.primary,
      textColor: AppColors.ink,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      titleTextStyle: GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryDark,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface.withValues(alpha: 0.78),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface.withValues(alpha: 0.92),
      elevation: 0,
      height: 72,
      indicatorColor: AppColors.primary.withValues(alpha: 0.16),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary);
        }
        return const IconThemeData(color: AppColors.muted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.muted,
        );
      }),
    ),
  );
}
