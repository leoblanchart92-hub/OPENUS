import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_info.dart';
import '../../core/theme/openus_theme.dart';
import '../../domain/ai.dart';
import '../../domain/conversation.dart';
import '../../services/voice/voice_controller.dart';
import '../../state/conversation_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/assistant_orb.dart';
import '../widgets/message_bubble.dart';
import '../widgets/neon_panel.dart';
import '../widgets/status_pill.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.onSettings});
  final VoidCallback onSettings;
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}
class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _inputFocus = FocusNode();
  String? _lastMessageId;
  String? _lastVoiceError;
  late final VoiceController _voice;

  @override
  void initState() {
    super.initState();
    _voice = context.read<VoiceController>();
    _voice.addListener(_voiceChanged);
  }
  void _voiceChanged() {
    if (_voice.error != null && _voice.error != _lastVoiceError && mounted) {
      _lastVoiceError = _voice.error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_voice.error!)));
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = context.watch<ConversationController>().active;
    final id = active?.messages.lastOrNull?.id;
    if (id != _lastMessageId) {
      _lastMessageId = id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
  }
  Future<void> _send() async {
    final chats = context.read<ConversationController>();
    final text = _input.text.trim();
    if (chats.generating || text.isEmpty || text.length > AppInfo.maxMessageLength) return;
    final voice = context.read<VoiceController>();
    final autoSpeak = context.read<SettingsController>().settings.autoSpeak;
    if (voice.listening) await voice.stopListening();
    if (!mounted) return;
    _input.clear();
    final reply = await chats.send(text);
    if (reply != null && autoSpeak && mounted) await voice.speak(reply);
  }
  @override
  void dispose() {
    _voice.removeListener(_voiceChanged);
    if (_voice.listening) _voice.stopListening();
    _input.dispose(); _scroll.dispose(); _inputFocus.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chats = context.watch<ConversationController>();
    final settings = context.watch<SettingsController>().settings;
    final voice = context.watch<VoiceController>();
    final messages = chats.active?.messages ?? const <ChatMessage>[];
    final compact = MediaQuery.sizeOf(context).width < 680;
    final mode = switch (settings.mode) { AiMode.local => 'LOCAL', AiMode.internet => 'INTERNET', AiMode.automatic => 'AUTO' };
    return Column(children: [
      Container(padding: EdgeInsets.fromLTRB(compact ? 18 : 32, compact ? 16 : 24, compact ? 18 : 32, 18),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: OpenUsColors.border))),
        child: Row(children: [
          if (messages.isNotEmpty) ...[AssistantOrb(size: 42, active: chats.generating), const SizedBox(width: 13)],
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assistant', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4), Text(chats.generating ? 'Connexion au moteur en cours' : 'Votre espace de réflexion', style: const TextStyle(fontSize: 11, color: OpenUsColors.muted)),
          ])),
          if (!compact) ...[StatusPill(label: mode, color: OpenUsColors.blue, tooltip: 'Mode de sélection du moteur'), const SizedBox(width: 10)],
          const EngineStatusPill(),
          if (!compact) ...[const SizedBox(width: 12), IconButton(tooltip: 'Paramètres du moteur', onPressed: widget.onSettings, icon: const Icon(Icons.tune_rounded, size: 20))],
        ])),
      Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 920), child: chats.loading
        ? const Center(child: CircularProgressIndicator())
        : messages.isEmpty ? _Welcome(onSettings: widget.onSettings, active: voice.listening)
        : ListView.builder(controller: _scroll, padding: EdgeInsets.fromLTRB(compact ? 16 : 32, 26, compact ? 16 : 32, 12),
          itemCount: messages.length, itemBuilder: (_, index) => MessageBubble(message: messages[index], onCancel: chats.cancelGeneration))))),
      Padding(padding: EdgeInsets.fromLTRB(compact ? 12 : 28, 0, compact ? 12 : 28, compact ? 12 : 20),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860), child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (chats.storageNotice != null) NoticeBanner(message: chats.storageNotice!, warning: true),
          if (!settings.anyEngineConfigured) NoticeBanner(message: 'Aucun moteur connecté. Les réponses IA nécessitent une configuration.',
            action: IconButton(tooltip: 'Configurer un moteur', onPressed: widget.onSettings, icon: const Icon(Icons.arrow_forward_rounded, size: 18))),
          CallbackShortcuts(bindings: {const SingleActivator(LogicalKeyboardKey.enter, control: true): _send},
            child: NeonPanel(padding: const EdgeInsets.fromLTRB(8, 8, 10, 8), glow: voice.listening,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                IconButton(tooltip: voice.listening ? 'Arrêter la dictée' : 'Dicter un message',
                  onPressed: voice.busy ? null : () => voice.toggleListening(_input.text, (text) {
                    if (!mounted) return;
                    _input.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
                  }),
                  icon: Icon(voice.listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: voice.listening ? Theme.of(context).colorScheme.primary : OpenUsColors.muted, size: 22)),
                Expanded(child: TextField(controller: _input, focusNode: _inputFocus, minLines: 1, maxLines: 5,
                  maxLength: AppInfo.maxMessageLength, keyboardType: TextInputType.multiline, textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                  decoration: InputDecoration(hintText: voice.listening ? 'Je vous écoute…' : 'Écrivez à OPENUS…',
                    filled: false, counterText: '', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13)))),
                const SizedBox(width: 6),
                Padding(padding: const EdgeInsets.only(bottom: 2), child: chats.generating
                  ? IconButton.filledTonal(tooltip: 'Annuler la génération', onPressed: chats.cancelGeneration, icon: const Icon(Icons.stop_rounded))
                  : ListenableBuilder(listenable: _input, builder: (_, _) => IconButton.filled(
                      tooltip: 'Envoyer le message', onPressed: _input.text.trim().isEmpty || chats.loading ? null : _send,
                      style: IconButton.styleFrom(minimumSize: const Size(44, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.arrow_upward_rounded, size: 22)))),
              ]))),
          const SizedBox(height: 9),
          Text(voice.listening ? 'Dictée active · appuyez sur le micro pour terminer · aucun envoi automatique'
              : compact ? 'Vos conversations sont stockées sur cet appareil.' : 'Entrée : nouvelle ligne  ·  Ctrl + Entrée : envoyer  ·  Historique local uniquement',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: OpenUsColors.muted)),
        ]))),
    ]);
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onSettings, required this.active});
  final VoidCallback onSettings;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    return SingleChildScrollView(padding: EdgeInsets.symmetric(horizontal: compact ? 22 : 40, vertical: 20),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Column(mainAxisSize: MainAxisSize.min, children: [
        AssistantOrb(size: compact ? 180 : 224, active: active),
        const SizedBox(height: 12),
        Text('L’INTELLIGENCE, À VOTRE SERVICE.', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, letterSpacing: 2.2, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Text('Bienvenue dans OPENUS.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: compact ? 29 : 38)),
        const SizedBox(height: 12),
        const Text('Un espace personnel pour penser, créer et avancer.\nConnectez votre moteur IA pour commencer.', textAlign: TextAlign.center,
          style: TextStyle(color: OpenUsColors.muted, fontSize: 14, height: 1.7)),
        const SizedBox(height: 28),
        NeonPanel(glow: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.hub_outlined, size: 20, color: OpenUsColors.blue), SizedBox(width: 10),
            Expanded(child: Text('Votre assistant, votre choix.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)))]),
          const SizedBox(height: 15),
          const _SetupLine(number: '01', title: 'Choisissez votre intelligence', description: 'Ollama sur votre machine, OpenAI ou Anthropic.'),
          const _SetupLine(number: '02', title: 'Gardez le contrôle', description: 'Local, Internet ou automatique. Vous décidez.'),
          const SizedBox(height: 17),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onSettings,
            icon: const Icon(Icons.tune_rounded, size: 18), label: const Text('Configurer un moteur'))),
          const SizedBox(height: 12),
          const Text('Aucune IA embarquée pour le moment. Aucune réponse simulée.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: OpenUsColors.muted)),
        ])),
      ]))));
  }
}
class _SetupLine extends StatelessWidget {
  const _SetupLine({required this.number, required this.title, required this.description});
  final String number;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 13), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(number, style: const TextStyle(fontFamily: 'monospace', color: OpenUsColors.muted, fontSize: 11)), const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 3), Text(description, style: const TextStyle(fontSize: 11, color: OpenUsColors.muted))])),
  ]));
}
