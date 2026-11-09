enum MessageSender {
  user,
  assistant,
  system,
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isDemo = true,
    this.providerLabel = 'Démo locale',
  });

  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final bool isDemo;
  final String providerLabel;

  bool get isUser => sender == MessageSender.user;
  bool get isAssistant => sender == MessageSender.assistant;
}
