import '../core/models/chat_message.dart';

/// Provider-agnostic request payload passed to any [AiProviderService].
class AiRequest {
  const AiRequest({
    required this.conversationId,
    required this.prompt,
    required this.history,
    this.modelId,
    this.temperature = 0.6,
    this.maxTokens = 1024,
  });

  final String conversationId;
  final String prompt;
  final List<ChatMessage> history;
  final String? modelId;
  final double temperature;
  final int maxTokens;
}
