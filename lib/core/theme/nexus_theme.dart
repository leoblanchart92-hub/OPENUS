import 'package:flutter/material.dart';
import 'nexus_colors.dart';

/// Builds the global dark Material 3 theme for Nexus AI.
abstract final class NexusTheme {
  static ThemeData buildDarkTheme() {
    const colorScheme = ColorScheme.dark(
      primary: NexusColors.neonViolet,
      onPrimary: NexusColors.textPrimary,
      primaryContainer: NexusColors.deepViolet,
      onPrimaryContainer: NexusColors.softVioletTint,
      secondary: NexusColors.electricViolet,
      onSecondary: NexusColors.voidBlack,
      secondaryContainer: NexusColors.surfaceElevated,
      onSecondaryContainer: NexusColors.softVioletTint,
      surface: NexusColors.obsidian,
      onSurface: NexusColors.textPrimary,
      surfaceContainerHighest: NexusColors.surfaceElevated,
      onSurfaceVariant: NexusColors.textSecondary,
      outline: NexusColors.borderSubtle,
      error: NexusColors.danger,
      onError: NexusColors.voidBlack,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NexusColors.voidBlack,
      canvasColor: NexusColors.obsidian,
      dividerColor: NexusColors.borderSubtle,
      splashColor: NexusColors.neonViolet.alphaFactor(0.14),
      highlightColor: NexusColors.neonViolet.alphaFactor(0.08),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: NexusColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: NexusColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: NexusColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: NexusColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.48,
          color: NexusColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: NexusColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: NexusColors.textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: NexusColors.textPrimary,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NexusColors.surfaceDark,
        hintStyle: const TextStyle(color: NexusColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: NexusColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: NexusColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: NexusColors.neonViolet,
            width: 1.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: NexusColors.neonViolet,
          foregroundColor: NexusColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NexusColors.textPrimary,
          side: const BorderSide(color: NexusColors.borderSubtle),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NexusColors.softVioletTint;
          }
          return NexusColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NexusColors.neonViolet;
          }
          return NexusColors.surfaceElevated;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NexusColors.electricViolet;
          }
          return NexusColors.borderSubtle;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: NexusColors.neonViolet,
        inactiveTrackColor: NexusColors.surfaceElevated,
        thumbColor: NexusColors.lavenderGlow,
        overlayColor: NexusColors.neonViolet.alphaFactor(0.18),
      ),
      dividerTheme: const DividerThemeData(
        color: NexusColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NexusColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: NexusColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: NexusColors.neonViolet.alphaFactor(0.4),
          ),
        ),
      ),
    );
  }
}
