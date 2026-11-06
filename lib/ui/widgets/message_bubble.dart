import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/openus_theme.dart';
import '../../domain/conversation.dart';
import '../../services/voice/voice_controller.dart';
import 'assistant_orb.dart';
import 'brand_mark.dart';
import 'neon_panel.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.onCancel});
  final ChatMessage message;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) {
    final user = message.role == MessageRole.user;
    final failed = message.status == MessageStatus.failed;
    final accent = failed ? OpenUsColors.danger : user ? Theme.of(context).colorScheme.primary : OpenUsColors.blue;
    final time = message.createdAt.toLocal();
    final stamp = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Padding(padding: const EdgeInsets.only(bottom: 24), child: Align(alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width < 600 ? 560 : 680),
        child: Column(crossAxisAlignment: user ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4), child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (!user) ...[const BrandMark(size: 15), const SizedBox(width: 7)],
            Text(user ? 'VOUS' : failed ? 'REQUÊTE INTERROMPUE' : 'OPENUS', style: TextStyle(fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: accent)),
            const SizedBox(width: 10), Text(stamp, style: const TextStyle(fontSize: 10, color: OpenUsColors.muted)),
          ])),
          NeonPanel(padding: const EdgeInsets.fromLTRB(18, 15, 18, 15), accent: accent, glow: false,
            child: message.status == MessageStatus.pending ? Row(mainAxisSize: MainAxisSize.min, children: [
              const AssistantOrb(size: 36, active: true), const SizedBox(width: 10),
              const Text('Requête en cours…', style: TextStyle(color: OpenUsColors.muted, fontSize: 13)),
              const SizedBox(width: 12), IconButton(tooltip: 'Annuler la génération', onPressed: onCancel, icon: const Icon(Icons.stop_rounded, size: 19)),
            ]) : SelectableText(message.content, style: TextStyle(fontSize: 14, height: 1.65, color: failed ? OpenUsColors.danger : OpenUsColors.text))),
          if (message.engineLabel != null || message.status == MessageStatus.completed) Padding(padding: const EdgeInsets.only(top: 5),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (message.engineLabel != null) Flexible(child: Text(message.engineLabel!, style: const TextStyle(fontSize: 10, color: OpenUsColors.muted))),
              if (!user && message.status == MessageStatus.completed) ...[
                const SizedBox(width: 8),
                _SmallAction(tooltip: 'Copier la réponse', icon: Icons.copy_rounded, onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: message.content));
                  messenger.showSnackBar(const SnackBar(content: Text('Réponse copiée.')));
                }),
                _SmallAction(tooltip: 'Lire à voix haute', icon: Icons.volume_up_outlined, onPressed: () {
                  final voice = context.read<VoiceController>();
                  if (voice.speaking) { voice.stopSpeaking(); } else { voice.speak(message.content); }
                }),
              ],
            ])),
        ]))));
  }
}
class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.tooltip, required this.icon, required this.onPressed});
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(width: 32, height: 30, child: IconButton(tooltip: tooltip,
    padding: EdgeInsets.zero, iconSize: 15, color: OpenUsColors.muted, onPressed: onPressed, icon: Icon(icon)));
}
