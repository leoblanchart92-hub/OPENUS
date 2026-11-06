import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/openus_theme.dart';
import '../../../domain/app_settings.dart';
import '../../../state/settings_controller.dart';
import '../../widgets/assistant_orb.dart';
import '../../widgets/neon_panel.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;
    Future<void> update(AppSettings next) => controller.update(next);
    return SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 4, 24, 36),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 830), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        NeonPanel(glow: settings.glowEnabled, child: Column(children: [
          const AssistantOrb(size: 156), const SizedBox(height: 14),
          Text('Noir profond. Lumière maîtrisée.', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8), const Text('Aperçu de votre signature visuelle', style: TextStyle(fontSize: 12, color: OpenUsColors.muted)),
        ])),
        const SizedBox(height: 20),
        NeonPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Couleur d’accent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (final choice in AccentChoice.values) ChoiceChip(label: Text(choice == AccentChoice.violet ? 'Violet néon' : 'Bleu électrique'),
              avatar: CircleAvatar(radius: 6, backgroundColor: choice == AccentChoice.violet ? OpenUsColors.violet : OpenUsColors.blue),
              selected: settings.accent == choice, onSelected: controller.busy ? null : (_) => update(settings.copyWith(accent: choice))),
          ]),
          const SizedBox(height: 18),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: settings.glowEnabled, title: const Text('Halos lumineux', style: TextStyle(fontSize: 14)),
            onChanged: controller.busy ? null : (value) => update(settings.copyWith(glowEnabled: value)),
            subtitle: const Text('Une lumière subtile autour du noyau et des panneaux.', style: TextStyle(fontSize: 12))),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: settings.reduceMotion, title: const Text('Réduire les animations', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Le noyau reste affiché, sans rotation continue.', style: TextStyle(fontSize: 12)),
            onChanged: controller.busy ? null : (value) => update(settings.copyWith(reduceMotion: value))),
        ])),
        const SizedBox(height: 20),
        const NoticeBanner(message: 'Le thème sombre est volontairement unique. Les préférences d’accessibilité du système sont respectées pour les animations. Le logo officiel sera intégré dès sa livraison dans assets/branding/.'),
      ]))));
  }
}
