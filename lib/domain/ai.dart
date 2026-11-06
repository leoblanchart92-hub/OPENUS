import 'conversation.dart';

enum AiMode { local, internet, automatic }

enum CloudProvider { openAi, anthropic, groq }

enum EngineKind { local, openAi, anthropic, groq }

extension CloudProviderInfo on CloudProvider {
  String get displayName => switch (this) {
    CloudProvider.openAi => 'OpenAI',
    CloudProvider.anthropic => 'Anthropic',
    CloudProvider.groq => 'Groq',
  };

  EngineKind get engineKind => switch (this) {
    CloudProvider.openAi => EngineKind.openAi,
    CloudProvider.anthropic => EngineKind.anthropic,
    CloudProvider.groq => EngineKind.groq,
  };

  /// A documented suggestion, not a claim about the user's account entitlement.
  String? get suggestedModel => switch (this) {
    CloudProvider.groq => 'llama-3.1-8b-instant',
    _ => null,
  };
}

class AiException implements Exception {
  const AiException(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
  @override
  String toString() => message;
}

/// An actual engine adapter. There is deliberately no demo/fake implementation.
abstract interface class AiEngine {
  EngineKind get kind;
  String get displayName;
  Future<EngineProbe> probe({String? apiKey});
  Future<AiReply> complete(AiRequest request);
}

class EngineProbe {
  const EngineProbe({
    required this.available,
    required this.message,
    this.models = const [],
    this.modelSizesBytes = const {},
  });
  final bool available;
  final String message;
  final List<String> models;
  final Map<String, int> modelSizesBytes;
}

class GenerationLimits {
  const GenerationLimits({this.maxOutputTokens = 2048, this.contextTokens});
  final int maxOutputTokens;
  final int? contextTokens;
}

class AiRequest {
  const AiRequest({
    required this.model,
    required this.messages,
    required this.systemPrompt,
    required this.cancelToken,
    this.apiKey,
    this.limits = const GenerationLimits(),
    this.timeout = const Duration(seconds: 120),
  });
  final String model;
  final List<ChatMessage> messages;
  final String systemPrompt;
  final String? apiKey;
  final GenerationLimits limits;
  final AiCancelToken cancelToken;
  final Duration timeout;
}

class AiReply {
  const AiReply({
    required this.kind,
    required this.content,
    required this.model,
    required this.engineLabel,
  });
  final EngineKind kind;
  final String content;
  final String model;
  final String engineLabel;
}

/// Closing the HTTP client aborts the underlying request, not just its UI spinner.
class AiCancelToken {
  final List<void Function()> _listeners = [];
  bool _cancelled = false;
  bool get isCancelled => _cancelled;

  void addListener(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  void removeListener(void Function() listener) => _listeners.remove(listener);
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const AiException('Génération annulée.', cancelled: true);
    }
  }
}
