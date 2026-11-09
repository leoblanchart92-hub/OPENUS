import 'package:flutter/material.dart';

/// Core color tokens for Nexus AI (obsidian dark & neon violet palette).
abstract final class NexusColors {
  static const Color voidBlack = Color(0xFF05050A);
  static const Color obsidian = Color(0xFF0A0A14);
  static const Color surfaceDark = Color(0xFF111120);
  static const Color surfaceElevated = Color(0xFF18182E);
  static const Color surfaceGlass = Color(0xFF141426);

  static const Color neonViolet = Color(0xFF8B5CF6);
  static const Color electricViolet = Color(0xFFA855F7);
  static const Color deepViolet = Color(0xFF6D28D9);
  static const Color lavenderGlow = Color(0xFFC084FC);
  static const Color softVioletTint = Color(0xFFE9D5FF);

  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textSecondary = Color(0xFFA5A3BD);
  static const Color textMuted = Color(0xFF6E6C87);

  static const Color borderSubtle = Color(0xFF272440);
  static const Color borderGlowing = Color(0xFF7C3AED);

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
}

/// Cross-version alpha helper compatible across Flutter 3.x releases without
/// relying on deprecated or version-specific color channel methods.
extension NexusColorOpacity on Color {
  Color alphaFactor(double opacity) {
    final clamped = opacity.clamp(0.0, 1.0);
    return withAlpha((clamped * 255).round());
  }
}

/// Color preset used to customize the Nyx animated companion aura.
class CompanionPalette {
  const CompanionPalette({
    required this.name,
    required this.description,
    required this.primary,
    required this.accent,
    required this.highlight,
    required this.chassisBase,
  });

  final String name;
  final String description;
  final Color primary;
  final Color accent;
  final Color highlight;
  final Color chassisBase;

  static const CompanionPalette neonViolet = CompanionPalette(
    name: 'Violet Néon',
    description: 'Identité signature Nexus AI : obsidian profond et halo violet électrique.',
    primary: Color(0xFF8B5CF6),
    accent: Color(0xFFA855F7),
    highlight: Color(0xFFE9D5FF),
    chassisBase: Color(0xFF121024),
  );

  static const CompanionPalette amethystPulse = CompanionPalette(
    name: 'Impulsion Améthyste',
    description: 'Contraste magenta-violet lumineux avec reflets cristallins.',
    primary: Color(0xFF9333EA),
    accent: Color(0xFFD946EF),
    highlight: Color(0xFFF5D0FE),
    chassisBase: Color(0xFF180F26),
  );

  static const CompanionPalette midnightPrism = CompanionPalette(
    name: 'Prisme Nocturne',
    description: 'Teinte indigo-violet feutrée pour les sessions nocturnes prolongées.',
    primary: Color(0xFF6366F1),
    accent: Color(0xFF8B5CF6),
    highlight: Color(0xFFDDD6FE),
    chassisBase: Color(0xFF0E1022),
  );
}
