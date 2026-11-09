import 'package:flutter/material.dart';

import '../core/theme/nexus_colors.dart';

/// Reusable dark glassmorphic container with optional neon violet glow.
class NeonGlassCard extends StatelessWidget {
  const NeonGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 20,
    this.highlighted = false,
    this.glowColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool highlighted;
  final Color? glowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = glowColor ?? NexusColors.neonViolet;
    final radius = BorderRadius.circular(borderRadius);

    final decoration = BoxDecoration(
      borderRadius: radius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: highlighted
            ? [
                accent.alphaFactor(0.16),
                NexusColors.surfaceDark,
              ]
            : [
                NexusColors.surfaceElevated.alphaFactor(0.72),
                NexusColors.surfaceDark.alphaFactor(0.92),
              ],
      ),
      border: Border.all(
        color: highlighted
            ? accent.alphaFactor(0.55)
            : NexusColors.borderSubtle,
        width: highlighted ? 1.2 : 1.0,
      ),
      boxShadow: highlighted
          ? [
              BoxShadow(
                color: accent.alphaFactor(0.18),
                blurRadius: 24,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    );

    if (onTap == null) {
      return Container(
        decoration: decoration,
        padding: padding,
        child: child,
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: accent.alphaFactor(0.14),
        highlightColor: accent.alphaFactor(0.08),
        child: Ink(
          decoration: decoration,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
