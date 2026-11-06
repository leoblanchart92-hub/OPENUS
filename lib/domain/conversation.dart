import '../core/ids.dart';

enum MessageRole { user, assistant, system }
enum MessageStatus { completed, pending, failed, cancelled }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.completed,
    this.engineLabel,
    this.error,
  });

  factory ChatMessage.create({
    required MessageRole role,
    required String content,
    MessageStatus status = MessageStatus.completed,
    String? engineLabel,
    DateTime? createdAt,
  }) => ChatMessage(
    id: newId(), role: role, content: content,
    createdAt: createdAt ?? DateTime.now().toUtc(),
    status: status, engineLabel: engineLabel,
  );

  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;
  final String? engineLabel;
  final String? error;

  ChatMessage copyWith({String? content, MessageStatus? status, String? engineLabel, String? error}) =>
      ChatMessage(id: id, role: role, content: content ?? this.content,
        createdAt: createdAt, status: status ?? this.status,
        engineLabel: engineLabel ?? this.engineLabel, error: error);

  Map<String, Object?> toJson() => {
    'id': id, 'role': role.name, 'content': content,
    'createdAt': createdAt.toUtc().toIso8601String(), 'status': status.name,
    if (engineLabel != null) 'engineLabel': engineLabel,
    if (error != null) 'error': error,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final role = MessageRole.values.byName(json['role'] as String);
    var status = MessageStatus.values.byName(json['status'] as String);
    // A process can be killed mid-request. Never restore a perpetual spinner.
    if (status == MessageStatus.pending) status = MessageStatus.cancelled;
    return ChatMessage(
      id: json['id'] as String, role: role, content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      status: status, engineLabel: json['engineLabel'] as String?, error: json['error'] as String?,
    );
  }
}

class Conversation {
  Conversation({required this.id, required this.createdAt, required this.updatedAt, List<ChatMessage> messages = const []})
      : messages = List.unmodifiable(messages);

  factory Conversation.create() {
    final now = DateTime.now().toUtc();
    return Conversation(id: newId(), createdAt: now, updatedAt: now);
  }

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  String get title {
    for (final message in messages) {
      if (message.role == MessageRole.user && message.content.trim().isNotEmpty) {
        final text = message.content.trim().replaceAll(RegExp(r'\s+'), ' ');
        return text.length <= 56 ? text : '${text.substring(0, 56)}…';
      }
    }
    return 'Nouvelle conversation';
  }

  Conversation withMessages(List<ChatMessage> value) => Conversation(
    id: id, createdAt: createdAt, updatedAt: DateTime.now().toUtc(), messages: value,
  );

  Map<String, Object?> toJson() => {
    'id': id, 'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
    messages: (json['messages'] as List).cast<Map<String, dynamic>>().map(ChatMessage.fromJson).toList(),
  );
}
