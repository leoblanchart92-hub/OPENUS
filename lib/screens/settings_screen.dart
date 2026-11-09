import 'package:flutter/material.dart';

import '../ai/groq_ai_contract.dart';
import '../core/theme/nexus_colors.dart';
import '../services/chat_service.dart';
import '../services/desktop_window_service.dart';
import '../settings/settings_controller.dart';
import '../widgets/neon_glass_card.dart';
import '../widgets/nexus_badge.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settingsController,
    required this.chatService,
    required this.desktopWindowService,
  });

  final SettingsController settingsController;
  final ChatService chatService;
  final DesktopWindowService desktopWindowService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        settingsController,
        desktopWindowService,
      ]),
      builder: (context, _) {
        final settings = settingsController.settings;
        final nativeWindows = desktopWindowService.isNativeWindowsSupported;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personnalisation visuelle, comportement du compagnon et '
                    'configuration préparée pour Groq.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),

                  // 1. Interface & Companion
                  NeonGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compagnon & Interface',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Compagnon flottant intégré dans l’app',
                          ),
                          subtitle: const Text(
                            'Affiche une bulle Nyx déplaçable sur Accueil, '
                            'Historique et Paramètres.',
                          ),
                          value: settings.showInAppFloatingCompanion,
                          onChanged:
                              settingsController.setShowInAppFloatingCompanion,
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Anneau orbital lumineux'),
                          subtitle: const Text(
                            'Active les particules et le halo autour de Nyx.',
                          ),
                          value: settings.showOrbitalAura,
                          onChanged: settingsController.setShowOrbitalAura,
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Réduire les animations'),
                          subtitle: const Text(
                            'Atténue l’amplitude du flottement continu pour le '
                            'confort visuel.',
                          ),
                          value: settings.reducedMotion,
                          onChanged: settingsController.setReducedMotion,
                        ),
                        Row(
                          children: [
                            const Text('Intensité néon'),
                            Expanded(
                              child: Slider(
                                value: settings.glowIntensity,
                                min: 0.2,
                                max: 1.0,
                                onChanged: settingsController.setGlowIntensity,
                              ),
                            ),
                            Text('${(settings.glowIntensity * 100).round()}%'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Windows desktop experience (honest capabilities)
                  NeonGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Fenêtre Windows 10 / 11',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            NexusBadge(
                              label: nativeWindows
                                  ? 'Win32 actif'
                                  : 'Aperçu intégré',
                              color: nativeWindows
                                  ? NexusColors.success
                                  : NexusColors.textSecondary,
                              showDot: nativeWindows,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nativeWindows
                              ? 'Le pont natif Win32 est connecté : le mode '
                                  'compact redimensionne la fenêtre et permet de '
                                  'la garder au-dessus des autres fenêtres.'
                              : 'Vous exécutez Nexus AI hors du runner natif '
                                  'Windows. Le mode flottant OS au-dessus des '
                                  'autres applications nécessite Windows 10/11, '
                                  'mais vous pouvez tester l’affichage compact.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Mode Compagnon Compact'),
                          subtitle: const Text(
                            'Réduit l’interface principale en mini-carte dédiée à Nyx.',
                          ),
                          value: desktopWindowService.isCompactView,
                          onChanged: desktopWindowService.setCompactView,
                        ),
                        if (nativeWindows) ...[
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Flottant au-dessus des autres fenêtres',
                            ),
                            subtitle: const Text(
                              'Maintient la fenêtre au premier plan (HWND_TOPMOST).',
                            ),
                            value: desktopWindowService.isAlwaysOnTop,
                            onChanged: (val) =>
                                desktopWindowService.setAlwaysOnTop(val),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: desktopWindowService.minimizeWindow,
                            icon: const Icon(Icons.minimize_rounded, size: 18),
                            label: const Text('Réduire la fenêtre principale'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Future Groq AI architecture (strictly Groq-only, inactive)
                  NeonGlassCard(
                    highlighted: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text(
                              'Intelligence Artificielle (Phase 2)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: NexusColors.textPrimary,
                              ),
                            ),
                            NexusBadge(
                              label: 'Groq uniquement • Inactif',
                              color: NexusColors.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Moteur actuel : ${chatService.aiProvider.displayName}. '
                          'L’architecture `AiProviderService` est préparée '
                          'exclusivement pour l’API Groq (aucun autre '
                          'fournisseur cloud n’est intégré).',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Modèle Groq présélectionné pour la phase suivante :',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: GroqConfig.availablePresets.map((preset) {
                            final selected =
                                settings.preferredGroqModelId == preset.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => settingsController
                                    .setPreferredGroqModel(preset.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: selected
                                        ? NexusColors.neonViolet
                                            .alphaFactor(0.14)
                                        : NexusColors.surfaceDark,
                                    border: Border.all(
                                      color: selected
                                          ? NexusColors.neonViolet
                                          : NexusColors.borderSubtle,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        selected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        size: 20,
                                        color: selected
                                            ? NexusColors.lavenderGlow
                                            : NexusColors.textMuted,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              preset.label,
                                              style: TextStyle(
                                                fontWeight: selected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                color: NexusColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              preset.description,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Demo data reset
                  NeonGlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Données de démonstration',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Réinitialise les discussions de démonstration '
                                'et les réglages par défaut.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            chatService.resetDemoConversations();
                            settingsController.resetDefaults();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Données et paramètres de démonstration réinitialisés.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          label: const Text('Réinitialiser'),
                        ),
                      ],
                    ),
                  ),
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
