import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/openus_theme.dart';
import '../../state/conversation_controller.dart';
import '../widgets/neon_panel.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.onOpen, required this.onNew});
  final VoidCallback onOpen;
  final VoidCallback onNew;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}
class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';
  Future<bool> _confirm(String title, String message, String action) async => await showDialog<bool>(
    context: context, builder: (dialogContext) => AlertDialog(title: Text(title), content: Text(message), actions: [
      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
      FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(action)),
    ])) ?? false;

  @override
  Widget build(BuildContext context) {
    final chats = context.watch<ConversationController>();
    final all = chats.conversations.where((c) => c.messages.isNotEmpty).toList();
    final query = _query.toLowerCase().trim();
    final conversations = all.where((c) => query.isEmpty || c.title.toLowerCase().contains(query) || c.messages.any((m) => m.content.toLowerCase().contains(query))).toList();
    return SingleChildScrollView(padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 680 ? 20 : 36),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHeading('MÉMOIRE LOCALE', 'Vos conversations', description: 'Retrouvez vos échanges, uniquement sur cet appareil.',
          trailing: IconButton.filledTonal(tooltip: 'Nouvelle conversation', onPressed: widget.onNew, icon: const Icon(Icons.add_rounded))),
        if (chats.storageNotice != null) NoticeBanner(message: chats.storageNotice!, warning: true),
        TextField(onChanged: (value) => setState(() => _query = value), decoration: const InputDecoration(
          hintText: 'Rechercher dans vos conversations…', prefixIcon: Icon(Icons.search_rounded, size: 21))),
        const SizedBox(height: 20),
        if (conversations.isEmpty) NeonPanel(child: Padding(padding: const EdgeInsets.symmetric(vertical: 36), child: Column(children: [
          const Icon(Icons.forum_outlined, size: 42, color: OpenUsColors.muted), const SizedBox(height: 18),
          Text(query.isEmpty ? 'Tout commence par une conversation.' : 'Aucun résultat.', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 10), Text(query.isEmpty ? 'Vos échanges enregistrés apparaîtront ici.' : 'Essayez un autre mot ou créez un nouvel échange.',
            textAlign: TextAlign.center, style: const TextStyle(color: OpenUsColors.muted)),
          const SizedBox(height: 22), OutlinedButton.icon(onPressed: widget.onNew, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Nouvelle conversation')),
        ]))) else ...[
          for (final conversation in conversations) Padding(padding: const EdgeInsets.only(bottom: 12), child: NeonPanel(padding: const EdgeInsets.all(6),
            child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: OpenUsColors.blue),
              title: Text(conversation.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Padding(padding: const EdgeInsets.only(top: 7), child: Text('${conversation.createdAt.toLocal().day.toString().padLeft(2, '0')}/${conversation.createdAt.toLocal().month.toString().padLeft(2, '0')}/${conversation.createdAt.toLocal().year}  ·  ${conversation.messages.length} message(s)', style: const TextStyle(fontSize: 11, color: OpenUsColors.muted))),
              trailing: IconButton(tooltip: 'Supprimer cette conversation', icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (await _confirm('Supprimer cet échange ?', 'Cette conversation sera définitivement supprimée de cet appareil.', 'Supprimer')) {
                    final success = await chats.delete(conversation.id);
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text(success ? 'Conversation supprimée.' : 'Suppression impossible. Voir le message de stockage.')));
                  }
                }),
              onTap: () { chats.select(conversation.id); widget.onOpen(); }))),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            if (await _confirm('Effacer tout l’historique ?', 'Tous les messages enregistrés seront supprimés. Vos paramètres et vos clés API seront conservés.', 'Tout effacer')) {
              final success = await chats.clear();
              if (!mounted) return;
              messenger.showSnackBar(SnackBar(content: Text(success ? 'Historique effacé.' : 'Effacement impossible. L’historique est conservé.')));
            }
          }, icon: const Icon(Icons.delete_sweep_outlined, size: 18), label: const Text('Effacer l’historique'))),
        ],
        const SizedBox(height: 18),
        const Text('L’historique local n’est pas chiffré par OPENUS. Ne partagez pas les fichiers de l’application. La mémoire sémantique et la synchronisation ne sont pas intégrées.',
          style: TextStyle(color: OpenUsColors.muted, fontSize: 11, height: 1.6)),
      ]))));
  }
}
