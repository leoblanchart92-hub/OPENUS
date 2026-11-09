import 'package:flutter/material.dart';

import '../companion/companion_controller.dart';
import '../companion/companion_state.dart';
import '../companion/nexus_companion.dart';
import '../core/theme/nexus_colors.dart';
import '../services/chat_service.dart';
import '../services/desktop_window_service.dart';
import '../widgets/chat_composer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/nexus_badge.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({
    super.key,
    required this.chatService,
    required this.companionController,
    required this.desktopWindowService,
  });

  final ChatService chatService;
  final CompanionController companionController;
  final DesktopWindowService desktopWindowService;

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;
  String? _lastConvId;

  static const List<String> _starterSuggestions = [
    'Présente-toi Nyx !',
    'Comment fonctionne le mode compact Windows ?',
    'Parle-moi de la future API Groq',
  ];

  @override
  void initState() {
    super.initState();
    widget.chatService.addListener(_onChatUpdated);
    final active = widget.chatService.activeConversation;
    _lastConvId = active?.id;
    _lastMessageCount = active?.messages.length ?? 0;
  }

  @override
  void didUpdateWidget(covariant ConversationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatService != widget.chatService) {
      oldWidget.chatService.removeListener(_onChatUpdated);
      widget.chatService.addListener(_onChatUpdated);
    }
  }

  void _onChatUpdated() {
    final active = widget.chatService.activeConversation;
    final count = active?.messages.length ?? 0;
    if (active?.id != _lastConvId || count != _lastMessageCount) {
      _lastConvId = active?.id;
      _lastMessageCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    widget.chatService.removeListener(_onChatUpdated);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.chatService,
        widget.companionController,
      ]),
      builder: (context, _) {
        final active = widget.chatService.activeConversation;
        final messages = active?.messages ?? const [];
        final isGenerating = widget.chatService.isGenerating;
        final showSuggestions = messages.length <= 1 && !isGenerating;

        return SafeArea(
          top: false,
          child: Column(
            children: [
              // Compact companion & conversation header bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: NexusColors.surfaceDark.alphaFactor(0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: NexusColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    NexusCompanion(
                      controller: widget.companionController,
                      size: 46,
                      trackPointer: false,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  active?.title ?? 'Nouvelle discussion',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const NexusBadge(
                                label: 'DÉMO',
                                color: NexusColors.electricViolet,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Nyx • ${widget.companionController.state.statusText}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Nouvelle conversation démo',
                      onPressed: isGenerating
                          ? null
                          : () => widget.chatService.createNewConversation(),
                      icon: const Icon(
                        Icons.add_comment_rounded,
                        color: NexusColors.lavenderGlow,
                      ),
                    ),
                  ],
                ),
              ),

              // Message stream
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NexusCompanion(
                                controller: widget.companionController,
                                size: 120,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Aucune conversation active',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Envoyez un message ci-dessous pour démarrer '
                                'une discussion de démonstration avec Nyx.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        itemCount: messages.length + (isGenerating ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return const _ThinkingStatusRow();
                          }
                          return MessageBubble(message: messages[index]);
                        },
                      ),
              ),

              if (showSuggestions)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _starterSuggestions.map((suggestion) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            backgroundColor: NexusColors.surfaceElevated,
                            side: BorderSide(
                              color: NexusColors.neonViolet.alphaFactor(0.35),
                            ),
                            label: Text(
                              suggestion,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: NexusColors.softVioletTint,
                              ),
                            ),
                            onPressed: () =>
                                widget.chatService.sendMessage(suggestion),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                ),

              // Bottom message input bar (docked cleanly above soft keyboard)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: ChatComposer(
                  isBusy: isGenerating,
                  onFocusChanged: (focused) {
                    if (focused &&
                        widget.companionController.state ==
                            CompanionState.idle) {
                      widget.companionController.setState(CompanionState.waiting);
                    }
                  },
                  onSend: (text) => widget.chatService.sendMessage(text),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThinkingStatusRow extends StatelessWidget {
  const _ThinkingStatusRow();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: NexusColors.surfaceElevated.alphaFactor(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: NexusColors.neonViolet.alphaFactor(0.45),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: NexusColors.lavenderGlow,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Nyx réfléchit (simulation démo)...',
              style: TextStyle(
                fontSize: 13,
                color: NexusColors.softVioletTint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
