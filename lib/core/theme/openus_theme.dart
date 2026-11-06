import 'package:flutter/material.dart';
import '../../domain/app_settings.dart';

abstract final class OpenUsColors {
  static const background = Color(0xFF07080D);
  static const surface = Color(0xFF10121C);
  static const raised = Color(0xFF171A28);
  static const violet = Color(0xFFA17CFF);
  static const blue = Color(0xFF48AAFF);
  static const text = Color(0xFFF1F1FA);
  static const muted = Color(0xFF969CB5);
  static const border = Color(0xFF272B40);
  static const success = Color(0xFF6EDBB7);
  static const warning = Color(0xFFEDBD78);
  static const danger = Color(0xFFFF8496);
}

abstract final class OpenUsTheme {
  static ThemeData build(AppSettings settings) {
    final accent = settings.accent == AccentChoice.violet ? OpenUsColors.violet : OpenUsColors.blue;
    final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark).copyWith(
      primary: accent, secondary: OpenUsColors.blue,
      surface: OpenUsColors.surface, onSurface: OpenUsColors.text,
      onSurfaceVariant: OpenUsColors.muted, outline: OpenUsColors.border,
      error: OpenUsColors.danger,
    );
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: scheme, scaffoldBackgroundColor: OpenUsColors.background,
      canvasColor: OpenUsColors.background,
      textTheme: base.textTheme.apply(bodyColor: OpenUsColors.text, displayColor: OpenUsColors.text).copyWith(
        headlineLarge: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600, letterSpacing: -1.2, height: 1.15),
        headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -.7, height: 1.2),
        titleLarge: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600, letterSpacing: -.3),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.6),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
        labelSmall: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: OpenUsColors.background, surfaceTintColor: Colors.transparent, elevation: 0),
      cardTheme: CardThemeData(color: OpenUsColors.surface, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: OpenUsColors.border))),
      dividerTheme: const DividerThemeData(color: OpenUsColors.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: OpenUsColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFF727991), fontSize: 14),
        labelStyle: const TextStyle(color: OpenUsColors.muted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OpenUsColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OpenUsColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: OpenUsColors.danger)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: accent, foregroundColor: OpenUsColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontWeight: FontWeight.w700))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: OpenUsColors.text, side: const BorderSide(color: OpenUsColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: accent)),
      navigationRailTheme: NavigationRailThemeData(backgroundColor: OpenUsColors.background,
        selectedIconTheme: IconThemeData(color: accent), unselectedIconTheme: const IconThemeData(color: OpenUsColors.muted),
        indicatorColor: accent.withValues(alpha: .13)),
      snackBarTheme: SnackBarThemeData(backgroundColor: OpenUsColors.raised, contentTextStyle: const TextStyle(color: OpenUsColors.text),
        behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      dialogTheme: DialogThemeData(backgroundColor: OpenUsColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      tooltipTheme: TooltipThemeData(decoration: BoxDecoration(color: OpenUsColors.raised, borderRadius: BorderRadius.circular(8))),
    );
  }
}
