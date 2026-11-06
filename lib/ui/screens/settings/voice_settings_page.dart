import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/openus_theme.dart';
import '../../../services/voice/voice_controller.dart';
import '../../../state/settings_controller.dart';
import '../../widgets/neon_panel.dart';

class VoiceSettingsPage extends StatefulWidget {
  const VoiceSettingsPage({super.key});
  @override
  State<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends State<VoiceSettingsPage> {
  late bool _autoSpeak;
  late String _locale;
  late double _rate;
  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>().settings;
    _autoSpeak = settings.autoSpeak;
    _locale = settings.voiceLocale;
    _rate = settings.speechRate;
  }

  Future<bool> _save() async {
    final controller = context.read<SettingsController>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await controller.update(
      controller.settings.copyWith(
        autoSpeak: _autoSpeak,
        voiceLocale: _locale,
        speechRate: _rate,
      ),
    );
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Paramètres vocaux enregistrés.'
                : 'Enregistrement impossible.',
          ),
        ),
      );
    }
    return success;
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<SettingsController>().busy;
    final voice = context.watch<VoiceController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 830),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeonPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          color: OpenUsColors.blue,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Une voix pour votre assistant',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dictée à la demande et lecture des réponses via les services natifs. Aucun micro actif en arrière-plan.',
                      style: TextStyle(
                        color: OpenUsColors.muted,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _autoSpeak,
                      title: const Text(
                        'Lire les réponses automatiquement',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Uniquement après une réponse réelle du moteur.',
                        style: TextStyle(fontSize: 12),
                      ),
                      onChanged: busy
                          ? null
                          : (value) => setState(() => _autoSpeak = value),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _locale,
                      decoration: const InputDecoration(
                        labelText: 'Langue de la voix',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'fr-FR',
                          child: Text('Français — France'),
                        ),
                        DropdownMenuItem(
                          value: 'en-US',
                          child: Text('English — United States'),
                        ),
                        DropdownMenuItem(
                          value: 'en-GB',
                          child: Text('English — United Kingdom'),
                        ),
                        DropdownMenuItem(
                          value: 'es-ES',
                          child: Text('Español — España'),
                        ),
                        DropdownMenuItem(
                          value: 'de-DE',
                          child: Text('Deutsch — Deutschland'),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _locale = value);
                              }
                            },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Vitesse de lecture · ${(_rate * 100).round()} %',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Slider(
                      value: _rate,
                      min: .3,
                      max: .7,
                      divisions: 8,
                      label: '${(_rate * 100).round()} %',
                      onChanged: busy
                          ? null
                          : (value) => setState(() => _rate = value),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: busy || voice.busy
                              ? null
                              : () async {
                                  final voiceController = context.read<VoiceController>();
                                  if (await _save() && mounted) {
                                    if (voice.speaking) {
                                      await voice.stopSpeaking();
                                    } else {
                                      await voiceController.speak(
                                        'Ceci est un test de la synthèse vocale OPENUS. Aucun moteur d’intelligence artificielle n’est utilisé pour ce test.',
                                      );
                                    }
                                  }
                                },
                          icon: Icon(
                            voice.speaking
                                ? Icons.stop_rounded
                                : Icons.volume_up_outlined,
                            size: 19,
                          ),
                          label: Text(
                            voice.speaking
                                ? 'Arrêter la lecture'
                                : 'Tester la synthèse',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy || voice.busy
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final success = await context
                                      .read<VoiceController>()
                                      .initializeMicrophone();
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Service de reconnaissance disponible. Utilisez le micro dans l’assistant pour dicter.'
                                            : voice.error ??
                                                  'Service vocal indisponible.',
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.mic_none_rounded, size: 19),
                          label: const Text('Vérifier le microphone'),
                        ),
                      ],
                    ),
                    if (voice.error != null) ...[
                      const SizedBox(height: 16),
                      NoticeBanner(message: voice.error!, warning: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy ? null : _save,
                child: const Text('Enregistrer les paramètres vocaux'),
              ),
              const SizedBox(height: 24),
              const NoticeBanner(
                message:
                    'Android et Windows uniquement. La reconnaissance Windows est expérimentale. La disponibilité dépend du moteur vocal, des langues installées et des permissions.',
              ),
              const NoticeBanner(
                message:
                    'Confidentialité : sur Android, le service de reconnaissance peut transmettre l’audio à Google ou au fabricant. OPENUS n’enregistre pas de fichier audio. La dictée hors connexion nécessite un service système compatible.',
              ),
              const NoticeBanner(
                message:
                    'À développer : sélection avancée des voix, mot de réveil, conversation vocale continue et reconnaissance entièrement embarquée. La voix système par défaut est utilisée.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
