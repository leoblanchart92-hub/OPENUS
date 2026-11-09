import 'package:flutter/material.dart';

import '../companion/companion_controller.dart';
import '../companion/nexus_companion.dart';
import '../core/theme/nexus_colors.dart';
import '../services/chat_service.dart';
import '../services/desktop_window_service.dart';
import '../widgets/nexus_badge.dart';

/// Compact floating companion surface designed for Windows mini-window mode
/// and mobile/tablet preview of the desktop companion experience.
class CompactCompanionScreen extends StatefulWidget {
  const CompactCompanionScreen({
    super.key,
    required this.companionController,
    required this.chatService,
    required this.desktopWindowService,
    required this.onExpandToChat,
  });

  final CompanionController companionController;
  final ChatService chatService;
  final DesktopWindowService desktopWindowService;
  final VoidCallback onExpandToChat;

  @override
  State<CompactCompanionScreen> createState() => _CompactCompanionScreenState();
}

class _CompactCompanionScreenState extends State<CompactCompanionScreen> {
  final TextEditingController _quickInput = TextEditingController();

  @override
  void dispose() {
    _quickInput.dispose();
    super.dispose();
  }

  void _sendQuickMessage() {
    final text = _quickInput.text.trim();
    if (text.isEmpty || widget.chatService.isGenerating) {
      return;
    }
    _quickInput.clear();
    widget.chatService.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.voidBlack,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.companionController,
              widget.chatService,
              widget.desktopWindowService,
            ]),
            builder: (context, _) {
              final nativeSupported =
                  widget.desktopWindowService.isNativeWindowsSupported;
              final activeConv = widget.chatService.activeConversation;
              final latestMsg = activeConv != null &&
                      activeConv.messages.isNotEmpty
                  ? activeConv.messages.last.content
                  : 'Prêt pour un message rapide.';

              return Container(
                constraints: const BoxConstraints(maxWidth: 360, maxHeight: 460),
                margin: nativeSupported
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(nativeSupported ? 16 : 24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF131126),
                      NexusColors.voidBlack,
                    ],
                  ),
                  border: Border.all(
                    color: NexusColors.neonViolet.alphaFactor(0.55),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NexusColors.neonViolet.alphaFactor(0.22),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Draggable header bar on Windows
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: nativeSupported
                          ? (_) => widget.desktopWindowService.startWindowDrag()
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: NexusColors.borderSubtle),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: NexusBadge(
                                    label: 'Nyx Compact',
                                    showDot: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (nativeSupported)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: widget.desktopWindowService.isAlwaysOnTop
                                    ? 'Détacher du premier plan'
                                    : 'Garder au-dessus des fenêtres',
                                onPressed: () =>
                                    widget.desktopWindowService.setAlwaysOnTop(
                                  !widget.desktopWindowService.isAlwaysOnTop,
                                ),
                                icon: Icon(
                                  widget.desktopWindowService.isAlwaysOnTop
                                      ? Icons.push_pin_rounded
                                      : Icons.push_pin_outlined,
                                  size: 17,
                                  color: widget.desktopWindowService.isAlwaysOnTop
                                      ? NexusColors.lavenderGlow
                                      : NexusColors.textSecondary,
                                ),
                              ),
                            if (nativeSupported)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Réduire',
                                onPressed:
                                    widget.desktopWindowService.minimizeWindow,
                                icon: const Icon(
                                  Icons.minimize_rounded,
                                  size: 17,
                                  color: NexusColors.textSecondary,
                                ),
                              ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Agrandir l’interface complète',
                              onPressed: () => widget.desktopWindowService
                                  .setCompactView(false),
                              icon: const Icon(
                                Icons.open_in_full_rounded,
                                size: 17,
                                color: NexusColors.lavenderGlow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Companion core stage
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableHeight = constraints.maxHeight;
                          final companionSize = (availableHeight * 0.56)
                              .clamp(48.0, 128.0);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                NexusCompanion(
                                  controller: widget.companionController,
                                  size: companionSize,
                                ),
                                if (availableHeight > 110) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.companionController.state.statusText,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: NexusColors.softVioletTint,
                                    ),
                                  ),
                                ],
                                if (availableHeight > 175) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: NexusColors.surfaceDark,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: NexusColors.borderSubtle,
                                      ),
                                    ),
                                    child: Text(
                                      latestMsg.replaceAll('\n', ' '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: NexusColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Quick prompt + expand to full chat
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quickInput,
                              enabled: !widget.chatService.isGenerating,
                              onSubmitted: (_) => _sendQuickMessage(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: NexusColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Message rapide (démo)...',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            tooltip: 'Envoyer',
                            onPressed: widget.chatService.isGenerating
                                ? null
                                : _sendQuickMessage,
                            icon: const Icon(
                              Icons.arrow_upward_rounded,
                              color: NexusColors.lavenderGlow,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Ouvrir dans Conversations',
                            onPressed: () async {
                              final onExpand = widget.onExpandToChat;
                              onExpand();
                              await widget.desktopWindowService
                                  .setCompactView(false);
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                              color: NexusColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
