import '../../domain/conversation.dart';

/// Bounded conversation context, NOT semantic/long-term memory.
/// Only the active conversation is used; errors and pending replies are excluded.
abstract final class ConversationContext {
  static List<ChatMessage> build(Conversation conversation, int limit) {
    final complete = conversation.messages
        .where(
          (m) =>
              m.status == MessageStatus.completed &&
              m.content.trim().isNotEmpty &&
              (m.role == MessageRole.user || m.role == MessageRole.assistant),
        )
        .toList();
    final recent = complete.length <= limit
        ? complete
        : complete.sublist(complete.length - limit);
    // Anthropic requires the first non-system message to belong to the user.
    // All supported chat APIs accept a context beginning at a user turn.
    final start = recent.indexWhere((m) => m.role == MessageRole.user);
    return start < 0 ? const [] : List.unmodifiable(recent.sublist(start));
  }
}
