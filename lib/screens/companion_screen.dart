import 'package:flutter/material.dart';

import '../companion/companion_controller.dart';
import '../companion/companion_state.dart';
import '../companion/nexus_companion.dart';
import '../core/responsive/responsive_layout.dart';
import '../core/theme/nexus_colors.dart';
import '../services/desktop_window_service.dart';
import '../settings/settings_controller.dart';
import '../widgets/neon_glass_card.dart';
import '../widgets/nexus_badge.dart';

class CompanionScreen extends StatelessWidget {
  const CompanionScreen({
    super.key,
    required this.companionController,
    required this.settingsController,
    required this.desktopWindowService,
  });

  final CompanionController companionController;
  final SettingsController settingsController;
  final DesktopWindowService desktopWindowService;

  @override
  Widget build(BuildContext context) {
    final screenClass = ResponsiveLayout.of(context);
    final isNarrow = screenClass == NexusScreenClass.mobile ||
        screenClass == NexusScreenClass.compactWindow;

    return AnimatedBuilder(
      animation: Listenable.merge([
        companionController,
        settingsController,
        desktopWindowService,
      ]),
      builder: (context, _) {
        final state = companionController.state;
        final mood = companionController.mood;
        final settings = settingsController.settings;

        final stageCard = NeonGlassCard(
          highlighted: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  NexusBadge(
                    label: state.label,
                    showDot: true,
                  ),
                  const SizedBox(width: 8),
                  NexusBadge(
                    label: mood.label,
                    color: NexusColors.electricViolet,
                  ),
                  Text(
                    'Interactions : ${companionController.interactionCount}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      companionController.paletteId.palette.primary
                          .alphaFactor(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: NexusCompanion(
                  controller: companionController,
                  size: isNarrow ? 185 : 220,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                state.statusText,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                state.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: companionController.tapCompanion,
                    icon: const Icon(Icons.touch_app_rounded, size: 18),
                    label: const Text('Déclencher une réaction'),
                  ),
                  OutlinedButton.icon(
                    onPressed: desktopWindowService.toggleCompactView,
                    icon: const Icon(
                      Icons.picture_in_picture_alt_rounded,
                      size: 18,
                    ),
                    label: const Text('Vue compacte'),
                  ),
                ],
              ),
            ],
          ),
        );

        final controlsColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeonGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'États d’animation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Testez chaque cycle comportemental de Nyx (repos, '
                    'réaction, réflexion, parole, attente).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CompanionState.values.map((candidate) {
                      final selected = state == candidate;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(candidate.label),
                        selectedColor:
                            NexusColors.neonViolet.alphaFactor(0.32),
                        side: BorderSide(
                          color: selected
                              ? NexusColors.neonViolet
                              : NexusColors.borderSubtle,
                        ),
                        onSelected: (_) {
                          if (candidate == CompanionState.reacting) {
                            companionController.tapCompanion();
                          } else {
                            companionController.setState(candidate);
                          }
                        },
                      );
                    }).toList(growable: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            NeonGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expressions faciales',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CompanionMood.values.map((candidate) {
                      final selected = mood == candidate;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(candidate.label),
                        selectedColor:
                            NexusColors.electricViolet.alphaFactor(0.28),
                        side: BorderSide(
                          color: selected
                              ? NexusColors.electricViolet
                              : NexusColors.borderSubtle,
                        ),
                        onSelected: (_) =>
                            companionController.setMood(candidate),
                      );
                    }).toList(growable: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            NeonGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signature visuelle & Aura',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CompanionPaletteId.values.map((preset) {
                      final selected = settings.paletteId == preset;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(preset.palette.name),
                        avatar: CircleAvatar(
                          backgroundColor: preset.palette.accent,
                          radius: 7,
                        ),
                        selectedColor:
                            preset.palette.primary.alphaFactor(0.28),
                        side: BorderSide(
                          color: selected
                              ? preset.palette.accent
                              : NexusColors.borderSubtle,
                        ),
                        onSelected: (_) =>
                            settingsController.setPalette(preset),
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Anneau orbital & particules'),
                    subtitle: const Text(
                      'Affiche l’orbite lumineuse autour de Nyx.',
                    ),
                    value: settings.showOrbitalAura,
                    onChanged: settingsController.setShowOrbitalAura,
                  ),
                  const SizedBox(height: 4),
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
          ],
        );

        return SingleChildScrollView(
          padding: EdgeInsets.all(isNarrow ? 16 : 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Studio Compagnon Nyx',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Déplacez le curseur ou le doigt sur la scène pour '
                    'orienter le regard de Nyx.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  if (isNarrow)
                    Column(
                      children: [
                        stageCard,
                        const SizedBox(height: 14),
                        controlsColumn,
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: stageCard),
                        const SizedBox(width: 18),
                        Expanded(flex: 6, child: controlsColumn),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
