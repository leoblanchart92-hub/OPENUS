import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models/chat_message.dart';
import '../core/theme/nexus_colors.dart';
import 'nexus_badge.dart';

/// Styled conversation bubble for both user prompts and Nexus AI replies.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _copyText(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: message.content));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copié dans le presse-papiers.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxBubbleWidth = (MediaQuery.sizeOf(context).width * 0.78).clamp(
      240.0,
      640.0,
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 20),
            ),
            gradient: isUser
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NexusColors.deepViolet,
                      NexusColors.neonViolet,
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NexusColors.surfaceElevated,
                      NexusColors.surfaceDark,
                    ],
                  ),
            border: Border.all(
              color: isUser
                  ? NexusColors.lavenderGlow.alphaFactor(0.45)
                  : NexusColors.borderSubtle,
            ),
            boxShadow: isUser
                ? [
                    BoxShadow(
                      color: NexusColors.neonViolet.alphaFactor(0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      isUser ? 'Vous' : 'Nexus AI • Nyx',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isUser
                            ? NexusColors.softVioletTint
                            : NexusColors.lavenderGlow,
                      ),
                    ),
                  ),
                  if (!isUser && message.isDemo) ...[
                    const SizedBox(width: 8),
                    const NexusBadge(
                      label: 'Démo',
                      color: NexusColors.electricViolet,
                    ),
                  ],
                  const SizedBox(width: 14),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser
                          ? NexusColors.softVioletTint.alphaFactor(0.8)
                          : NexusColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _copyText(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: isUser
                            ? NexusColors.softVioletTint.alphaFactor(0.85)
                            : NexusColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                message.content,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.48,
                  color: NexusColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
