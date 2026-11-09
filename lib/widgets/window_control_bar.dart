import 'package:flutter/material.dart';

import '../core/theme/nexus_colors.dart';
import '../services/desktop_window_service.dart';
import 'nexus_badge.dart';

/// Top bar exposing active view title, clear demo badge, compact mode switch,
/// and real native Windows desktop controls when supported.
class WindowControlBar extends StatelessWidget {
  const WindowControlBar({
    super.key,
    required this.title,
    required this.desktopWindowService,
    this.showCompactButton = true,
  });

  final String title;
  final DesktopWindowService desktopWindowService;
  final bool showCompactButton;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: desktopWindowService,
      builder: (context, _) {
        final nativeSupported = desktopWindowService.isNativeWindowsSupported;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: NexusColors.obsidian.alphaFactor(0.75),
            border: const Border(
              bottom: BorderSide(color: NexusColors.borderSubtle),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const NexusBadge(
                      label: 'Mode Démo',
                      showDot: true,
                    ),
                  ],
                ),
              ),
              if (showCompactButton)
                OutlinedButton.icon(
                  onPressed: desktopWindowService.toggleCompactView,
                  icon: const Icon(Icons.picture_in_picture_alt_rounded, size: 17),
                  label: const Text('Compagnon compact'),
                ),
              if (nativeSupported) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: desktopWindowService.isAlwaysOnTop
                      ? 'Désactiver le maintien au premier plan'
                      : 'Garder au-dessus des fenêtres',
                  onPressed: () => desktopWindowService.setAlwaysOnTop(
                    !desktopWindowService.isAlwaysOnTop,
                  ),
                  icon: Icon(
                    desktopWindowService.isAlwaysOnTop
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    color: desktopWindowService.isAlwaysOnTop
                        ? NexusColors.lavenderGlow
                        : NexusColors.textSecondary,
                  ),
                ),
                IconButton(
                  tooltip: 'Réduire la fenêtre',
                  onPressed: desktopWindowService.minimizeWindow,
                  icon: const Icon(
                    Icons.minimize_rounded,
                    color: NexusColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
