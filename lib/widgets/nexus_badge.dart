import 'package:flutter/material.dart';

import '../core/theme/nexus_colors.dart';

/// Compact status pill used across Nexus AI to surface demo mode,
/// companion states, and platform readiness clearly.
class NexusBadge extends StatelessWidget {
  const NexusBadge({
    super.key,
    required this.label,
    this.color = NexusColors.neonViolet,
    this.icon,
    this.showDot = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.alphaFactor(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.alphaFactor(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.alphaFactor(0.7),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: color == NexusColors.neonViolet
                  ? NexusColors.softVioletTint
                  : color,
            ),
          ),
        ],
      ),
    );
  }
}
