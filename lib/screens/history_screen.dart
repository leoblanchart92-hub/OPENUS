import 'package:flutter/material.dart';

import '../core/theme/nexus_colors.dart';
import '../services/chat_service.dart';
import '../widgets/neon_glass_card.dart';
import '../widgets/nexus_badge.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.chatService,
    required this.onOpenConversation,
  });

  final ChatService chatService;
  final VoidCallback onOpenConversation;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm • $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.chatService,
      builder: (context, _) {
        final items = widget.chatService.filterConversations(_query);
        final activeId = widget.chatService.activeConversation?.id;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Historique des discussions',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Conversations de démonstration enregistrées '
                              'localement durant la session.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () {
                          widget.chatService.createNewConversation();
                          widget.onOpenConversation();
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Nouvelle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: NexusColors.textSecondary,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                      hintText: 'Rechercher une discussion ou un mot-clé...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: NeonGlassCard(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.history_toggle_off_rounded,
                                    size: 40,
                                    color: NexusColors.lavenderGlow,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _query.isEmpty
                                        ? 'Aucune conversation dans l’historique'
                                        : 'Aucun résultat pour « $_query »',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed:
                                        widget.chatService.resetDemoConversations,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text(
                                      'Restaurer les démos initiales',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final conv = items[index];
                              final isActive = conv.id == activeId;
                              return NeonGlassCard(
                                highlighted: isActive,
                                onTap: () {
                                  widget.chatService.selectConversation(conv.id);
                                  widget.onOpenConversation();
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: NexusColors.neonViolet
                                            .alphaFactor(0.16),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.forum_rounded,
                                        color: NexusColors.lavenderGlow,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                conv.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              NexusBadge(
                                                label: conv.topicTag,
                                                color: NexusColors.electricViolet,
                                              ),
                                              if (isActive)
                                                const NexusBadge(
                                                  label: 'Active',
                                                  color: NexusColors.success,
                                                  showDot: true,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            conv.lastMessagePreview,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${conv.messages.length} messages • '
                                            '${_formatDate(conv.updatedAt)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Supprimer cette discussion',
                                      onPressed: () {
                                        widget.chatService
                                            .deleteConversation(conv.id);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Conversation de démonstration supprimée.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: NexusColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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
