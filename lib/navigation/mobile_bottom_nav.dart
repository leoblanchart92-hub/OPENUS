import 'package:flutter/material.dart';

import '../core/theme/nexus_colors.dart';
import 'nexus_destination.dart';

/// Touch-friendly dark neon bottom navigation bar for Android and iOS phones.
class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final NexusDestination selected;
  final ValueChanged<NexusDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NexusColors.obsidian.alphaFactor(0.96),
        border: const Border(
          top: BorderSide(color: NexusColors.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: NexusDestination.values.map((dest) {
              final active = dest == selected;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelect(dest),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: active
                          ? NexusColors.neonViolet.alphaFactor(0.18)
                          : Colors.transparent,
                      border: Border.all(
                        color: active
                            ? NexusColors.neonViolet.alphaFactor(0.45)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active ? dest.activeIcon : dest.icon,
                          size: 21,
                          color: active
                              ? NexusColors.softVioletTint
                              : NexusColors.textSecondary,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dest.mobileLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w500,
                            color: active
                                ? NexusColors.textPrimary
                                : NexusColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }
}
