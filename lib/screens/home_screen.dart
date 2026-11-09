import 'package:flutter/material.dart';

import '../companion/companion_controller.dart';
import '../companion/nexus_companion.dart';
import '../core/responsive/responsive_layout.dart';
import '../core/theme/nexus_colors.dart';
import '../services/chat_service.dart';
import '../services/desktop_window_service.dart';
import '../settings/settings_controller.dart';
import '../widgets/neon_glass_card.dart';
import '../widgets/nexus_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.companionController,
    required this.chatService,
    required this.settingsController,
    required this.desktopWindowService,
    required this.onOpenConversations,
    required this.onOpenCompanionStudio,
    required this.onOpenSettings,
  });

  final CompanionController companionController;
  final ChatService chatService;
  final SettingsController settingsController;
  final DesktopWindowService desktopWindowService;
  final VoidCallback onOpenConversations;
  final VoidCallback onOpenCompanionStudio;
  final VoidCallback onOpenSettings;

  static const List<({String title, String prompt, IconData icon})>
      _quickPrompts = [
    (
      title: 'Découvrir les animations de Nyx',
      prompt: 'Comment réagis-tu quand je t’envoie un message ?',
      icon: Icons.auto_awesome_rounded,
    ),
    (
      title: 'Architecture Groq prévue',
      prompt: 'Comment l’API Groq sera-t-elle intégrée dans Nexus AI ?',
      icon: Icons.hub_rounded,
    ),
    (
      title: 'Compagnon de bureau Windows',
      prompt: 'Explique-moi le mode compagnon compact et flottant sur Windows.',
      icon: Icons.desktop_windows_rounded,
    ),
  ];

  void _launchPrompt(BuildContext context, String prompt) {
    if (chatService.isGenerating) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nyx termine la réponse en cours, patientez un instant.'),
        ),
      );
      return;
    }
    chatService.createNewConversation(title: 'Session rapide démo');
    onOpenConversations();
    chatService.sendMessage(prompt);
  }

  @override
  Widget build(BuildContext context) {
    final screenClass = ResponsiveLayout.of(context);
    final isCompact = screenClass == NexusScreenClass.mobile ||
        screenClass == NexusScreenClass.compactWindow;

    return AnimatedBuilder(
      animation: Listenable.merge([
        companionController,
        chatService,
        settingsController,
        desktopWindowService,
      ]),
      builder: (context, _) {
        final latestConversation = chatService.conversations.isNotEmpty
            ? chatService.conversations.first
            : null;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroBanner(
                    companionController: companionController,
                    isCompact: isCompact,
                    onOpenConversations: onOpenConversations,
                    onOpenCompanionStudio: onOpenCompanionStudio,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Démarrages rapides (Démo)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lancez un échange simulé pour observer immédiatement les '
                    'animations et réactions de Nyx.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 820
                          ? 3
                          : (constraints.maxWidth >= 520 ? 2 : 1);
                      final spacing = 12.0;
                      final cardWidth =
                          (constraints.maxWidth - spacing * (columns - 1)) /
                              columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: _quickPrompts.map((item) {
                          return SizedBox(
                            width: cardWidth,
                            child: NeonGlassCard(
                              onTap: () => _launchPrompt(context, item.prompt),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: NexusColors.neonViolet
                                              .alphaFactor(0.16),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          size: 18,
                                          color: NexusColors.lavenderGlow,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 16,
                                        color: NexusColors.textMuted,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item.title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.prompt,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(growable: false),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 740;
                      final cards = [
                        NeonGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  NexusBadge(
                                    label: 'IA • Phase 1 Démo',
                                    color: NexusColors.electricViolet,
                                    showDot: true,
                                  ),
                                  NexusBadge(
                                    label: 'Groq prêt',
                                    color: NexusColors.lavenderGlow,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Architecture prête pour Groq',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Les réponses actuelles utilisent des données de '
                                'démonstration locales. Modèle Groq présélectionné '
                                'pour la suite : '
                                '${settingsController.settings.preferredGroqModelId}.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: onOpenSettings,
                                icon: const Icon(Icons.tune_rounded, size: 17),
                                label: const Text('Voir les paramètres IA'),
                              ),
                            ],
                          ),
                        ),
                        NeonGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  NexusBadge(
                                    label: desktopWindowService
                                            .isNativeWindowsSupported
                                        ? 'Windows Natif Actif'
                                        : 'Mode Multiplateforme',
                                    color: desktopWindowService
                                            .isNativeWindowsSupported
                                        ? NexusColors.success
                                        : NexusColors.neonViolet,
                                    showDot: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Compagnon compact & bureau',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                desktopWindowService.isNativeWindowsSupported
                                    ? 'Basculez en mini-fenêtre flottante '
                                        'déplaçable au-dessus de vos applications '
                                        'Windows 10/11.'
                                    : 'Prévisualisez la vue compacte du '
                                        'compagnon. Le maintien flottant au-dessus '
                                        'des fenêtres OS est réservé à Windows.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              FilledButton.tonalIcon(
                                onPressed:
                                    desktopWindowService.toggleCompactView,
                                icon: const Icon(
                                  Icons.picture_in_picture_alt_rounded,
                                  size: 17,
                                ),
                                label: const Text('Activer le mode compact'),
                              ),
                            ],
                          ),
                        ),
                      ];

                      if (!wide) {
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 12),
                            cards[1],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 14),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                  if (latestConversation != null) ...[
                    const SizedBox(height: 22),
                    NeonGlassCard(
                      onTap: () {
                        chatService.selectConversation(latestConversation.id);
                        onOpenConversations();
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: NexusColors.neonViolet.alphaFactor(0.16),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              color: NexusColors.lavenderGlow,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        latestConversation.title,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const NexusBadge(label: 'Démo'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  latestConversation.lastMessagePreview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: NexusColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.companionController,
    required this.isCompact,
    required this.onOpenConversations,
    required this.onOpenCompanionStudio,
  });

  final CompanionController companionController;
  final bool isCompact;
  final VoidCallback onOpenConversations;
  final VoidCallback onOpenCompanionStudio;

  @override
  Widget build(BuildContext context) {
    final infoColumn = Column(
      crossAxisAlignment:
          isCompact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: isCompact ? WrapAlignment.center : WrapAlignment.start,
          children: [
            NexusBadge(
              label: 'Nyx • ${companionController.state.statusText}',
              showDot: true,
            ),
            const NexusBadge(
              label: 'Données de démo',
              color: NexusColors.electricViolet,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Votre compagnon IA personnel, fluide sur bureau et mobile.',
          textAlign: isCompact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Interagissez avec Nyx, testez ses états animés en direct et '
          'discutez dans une interface sombre noir & violet néon.',
          textAlign: isCompact ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: isCompact ? WrapAlignment.center : WrapAlignment.start,
          children: [
            FilledButton.icon(
              onPressed: onOpenConversations,
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text('Démarrer une discussion'),
            ),
            OutlinedButton.icon(
              onPressed: onOpenCompanionStudio,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Studio Nyx'),
            ),
          ],
        ),
      ],
    );

    final companionStage = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NexusCompanion(
          controller: companionController,
          size: isCompact ? 132 : 164,
        ),
        const SizedBox(height: 4),
        Text(
          'Touchez Nyx pour interagir',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );

    return NeonGlassCard(
      highlighted: true,
      padding: EdgeInsets.all(isCompact ? 18 : 24),
      child: isCompact
          ? Column(
              children: [
                companionStage,
                const SizedBox(height: 14),
                infoColumn,
              ],
            )
          : Row(
              children: [
                Expanded(child: infoColumn),
                const SizedBox(width: 24),
                companionStage,
              ],
            ),
    );
  }
}
