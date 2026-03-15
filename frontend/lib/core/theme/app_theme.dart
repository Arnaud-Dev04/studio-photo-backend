import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Thème Material 3 dark luxueux pour le studio photo
class AppTheme {
  AppTheme._();

  // ── Styles de texte ──
  static TextStyle get _montserrat => GoogleFonts.montserrat();
  static TextStyle get _inter => GoogleFonts.inter();

  static TextTheme get _textTheme => TextTheme(
        // Titres — Montserrat bold
        displayLarge: _montserrat.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.gold,
          letterSpacing: 1.2,
        ),
        displayMedium: _montserrat.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displaySmall: _montserrat.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineLarge: _montserrat.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.gold,
        ),
        headlineMedium: _montserrat.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: _montserrat.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Titres de section
        titleLarge: _montserrat.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: _montserrat.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: _montserrat.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        // Corps — Inter
        bodyLarge: _inter.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: _inter.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodySmall: _inter.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
        // Labels
        labelLarge: _inter.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        labelMedium: _inter.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelSmall: _inter.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint,
        ),
      );

  /// Style pour les montants et chiffres (Montserrat bold yellow)
  static TextStyle get amountStyle => _montserrat.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.yellow,
      );

  /// Style pour les montants grands (dashboard)
  static TextStyle get bigAmountStyle => _montserrat.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.yellow,
      );

  // ── Thème dark complet ──
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.yellow,
          secondary: AppColors.gold,
          tertiary: AppColors.goldLight,
          error: AppColors.error,
          onPrimary: Color(0xFF0D0D0D),
          onSecondary: AppColors.textPrimary,
          onSurface: AppColors.textPrimary,
          onError: AppColors.textPrimary,
        ),
        textTheme: _textTheme,

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: _montserrat.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
          ),
          iconTheme: const IconThemeData(color: AppColors.gold),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.gold, width: 0.5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),

        // Boutons élevés
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.yellow,
            foregroundColor: const Color(0xFF0D0D0D),
            elevation: 4,
            shadowColor: AppColors.yellow.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: _montserrat.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Boutons texte
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.goldLight,
            textStyle: _inter.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Champs de saisie
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gold, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gold, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.yellow, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.0),
          ),
          hintStyle: _inter.copyWith(
            color: AppColors.textHint,
            fontSize: 14,
          ),
          labelStyle: _inter.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          prefixIconColor: AppColors.gold,
          suffixIconColor: AppColors.gold,
        ),

        // Chips
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.yellow,
          labelStyle: _inter.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          secondaryLabelStyle: _inter.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0D0D0D),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.gold, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),

        // Bottom nav (désactivé — on utilise un widget custom)
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.yellow,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: AppColors.gold,
          thickness: 0.5,
          space: 1,
        ),

        // Dialogues
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.gold, width: 0.5),
          ),
          titleTextStyle: _montserrat.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surface,
          contentTextStyle: _inter.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),

        // FAB
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.yellow,
          foregroundColor: Color(0xFF0D0D0D),
          elevation: 6,
          shape: CircleBorder(),
        ),

        // Icônes
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      );
}
