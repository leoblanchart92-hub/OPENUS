import 'chat_message.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.updatedAt,
    this.isDemo = true,
    this.topicTag = 'Démonstration',
  });

  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime updatedAt;
  final bool isDemo;
  final String topicTag;

  String get lastMessagePreview {
    if (messages.isEmpty) {
      return 'Nouvelle conversation de démonstration prête.';
    }
    final latest = messages.last.content.replaceAll('\n', ' ').trim();
    if (latest.length <= 92) {
      return latest;
    }
    return '${latest.substring(0, 89)}...';
  }

  Conversation copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
    bool? isDemo,
    String? topicTag,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      isDemo: isDemo ?? this.isDemo,
      topicTag: topicTag ?? this.topicTag,
    );
  }
}
