import 'package:flutter/material.dart';
import '../../../core/app_info.dart';
import '../../../core/theme/openus_theme.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/neon_panel.dart';

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 4, 24, 36),
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 830), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      NeonPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const BrandLockup(), const SizedBox(height: 26),
        Text('Votre assistant personnel, ouvert et modulaire.', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Text('OPENUS est construit avec Flutter et Dart pour Android et Windows. Cette première phase établit les fondations : interface, conversations, configuration et connecteurs.',
          style: TextStyle(color: OpenUsColors.muted, fontSize: 13, height: 1.7)),
        const SizedBox(height: 20),
        _InfoRow(label: 'Version', value: '${AppInfo.version} (build ${AppInfo.build})'),
        _InfoRow(label: 'Étape', value: AppInfo.phase),
        const _InfoRow(label: 'Plateformes cibles', value: 'Android · Windows 10/11'),
        const _InfoRow(label: 'Moteur IA embarqué', value: 'Non inclus'),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: () => showLicensePage(context: context, applicationName: AppInfo.name, applicationVersion: AppInfo.version),
          icon: const Icon(Icons.description_outlined, size: 18), label: const Text('Licences open source')),
      ])),
      const SizedBox(height: 20),
      const NeonPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('État des intégrations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)), SizedBox(height: 20),
        _Capability(label: 'Conversations et historique locaux', status: 'INTÉGRÉ', done: true),
        _Capability(label: 'Connecteurs Ollama, OpenAI, Anthropic', status: 'CONFIGURABLE', done: true),
        _Capability(label: 'Clés dans le stockage sécurisé natif', status: 'INTÉGRÉ', done: true),
        _Capability(label: 'Dictée et synthèse natives', status: 'SELON APPAREIL', done: true),
        _Capability(label: 'llama.cpp / modèles GGUF embarqués', status: 'À DÉVELOPPER'),
        _Capability(label: 'Mémoire sémantique et rappel personnel', status: 'À DÉVELOPPER'),
        _Capability(label: 'Streaming, outils et actions système', status: 'À DÉVELOPPER'),
        _Capability(label: 'Installateur Windows et signature', status: 'PHASE SUIVANTE'),
      ])),
      const SizedBox(height: 20),
      const NoticeBanner(message: 'Aucune fausse IA, aucune clé préinstallée, aucune télémétrie OPENUS. Une API configurée peut être payante. L’historique est local et non chiffré par OPENUS ; les clés utilisent un stockage distinct.'),
      const SizedBox(height: 10),
      const Text('Les connecteurs et la voix nécessitent des essais sur les appareils cibles. Une compilation ne remplace pas ces tests matériels.',
        style: TextStyle(fontSize: 11, color: OpenUsColors.muted, height: 1.6)),
    ]))));
}
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 11), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 150, child: Text(label, style: const TextStyle(fontSize: 12, color: OpenUsColors.muted))),
    Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
  ]));
}
class _Capability extends StatelessWidget {
  const _Capability({required this.label, required this.status, this.done = false});
  final String label;
  final String status;
  final bool done;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
    Icon(done ? Icons.check_circle_outline_rounded : Icons.schedule_rounded, size: 17, color: done ? OpenUsColors.success : OpenUsColors.muted),
    const SizedBox(width: 10), Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
    const SizedBox(width: 8), Text(status, style: TextStyle(fontSize: 8, letterSpacing: .6, color: done ? OpenUsColors.success : OpenUsColors.warning)),
  ]));
}
