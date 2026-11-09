import 'package:flutter/material.dart';

import '../companion/companion_controller.dart';
import '../companion/nexus_companion.dart';
import '../core/theme/nexus_colors.dart';
import '../services/desktop_window_service.dart';
import 'nexus_destination.dart';

/// Coucou-inspired obsidian sidebar for Windows desktop and tablet layouts.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onNewConversation,
    required this.companionController,
    required this.desktopWindowService,
    this.compactRail = false,
  });

  final NexusDestination selected;
  final ValueChanged<NexusDestination> onSelect;
  final VoidCallback onNewConversation;
  final CompanionController companionController;
  final DesktopWindowService desktopWindowService;
  final bool compactRail;

  @override
  Widget build(BuildContext context) {
    final width = compactRail ? 84.0 : 252.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: const BoxDecoration(
        color: NexusColors.obsidian,
        border: Border(
          right: BorderSide(color: NexusColors.borderSubtle),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Brand + mini companion header
            Padding(
              padding: EdgeInsets.fromLTRB(
                compactRail ? 12 : 16,
                16,
                compactRail ? 12 : 16,
                14,
              ),
              child: AnimatedBuilder(
                animation: companionController,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: compactRail
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      NexusCompanion(
                        controller: companionController,
                        size: compactRail ? 44 : 46,
                        trackPointer: false,
                        onTapOverride: () =>
                            onSelect(NexusDestination.companion),
                      ),
                      if (!compactRail) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nexus AI',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: NexusColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Nyx • ${companionController.state.label}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: NexusColors.lavenderGlow,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            // New Demo Conversation CTA
            Padding(
              padding: EdgeInsets.symmetric(horizontal: compactRail ? 12 : 16),
              child: compactRail
                  ? Tooltip(
                      message: 'Nouvelle discussion',
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: const Size(48, 46),
                        ),
                        onPressed: onNewConversation,
                        child: const Icon(Icons.add_rounded, size: 20),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onNewConversation,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Nouvelle discussion'),
                      ),
                    ),
            ),
            const SizedBox(height: 18),

            // Navigation destinations
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: compactRail ? 10 : 12,
                ),
                children: NexusDestination.values.map((dest) {
                  final active = dest == selected;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Tooltip(
                      message: compactRail ? dest.label : '',
                      child: InkWell(
                        onTap: () => onSelect(dest),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: EdgeInsets.symmetric(
                            horizontal: compactRail ? 0 : 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: active
                                ? LinearGradient(
                                    colors: [
                                      NexusColors.neonViolet.alphaFactor(0.24),
                                      NexusColors.deepViolet.alphaFactor(0.14),
                                    ],
                                  )
                                : null,
                            border: Border.all(
                              color: active
                                  ? NexusColors.neonViolet.alphaFactor(0.55)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: compactRail
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              Icon(
                                active ? dest.activeIcon : dest.icon,
                                size: 20,
                                color: active
                                    ? NexusColors.softVioletTint
                                    : NexusColors.textSecondary,
                              ),
                              if (!compactRail) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    dest.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: active
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: active
                                          ? NexusColors.textPrimary
                                          : NexusColors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (active)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: NexusColors.electricViolet,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: NexusColors.electricViolet
                                              .alphaFactor(0.8),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ),

            // Footer compact toggle + provider honesty badge
            Padding(
              padding: EdgeInsets.all(compactRail ? 10 : 14),
              child: Column(
                children: [
                  if (compactRail)
                    Tooltip(
                      message: 'Mode compagnon compact',
                      child: IconButton.outlined(
                        onPressed: desktopWindowService.toggleCompactView,
                        icon: const Icon(
                          Icons.picture_in_picture_alt_rounded,
                          size: 19,
                        ),
                      ),
                    )
                  else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NexusColors.surfaceDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: NexusColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'IA : Démo locale',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: NexusColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Groq prêt pour Phase 2',
                            style: TextStyle(
                              fontSize: 11,
                              color: NexusColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  desktopWindowService.toggleCompactView,
                              icon: const Icon(
                                Icons.picture_in_picture_alt_rounded,
                                size: 16,
                              ),
                              label: const Text('Mode compact'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
