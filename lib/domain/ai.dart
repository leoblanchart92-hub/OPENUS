import 'conversation.dart';

enum AiMode { local, internet, automatic }

enum CloudProvider { openAi, anthropic }

enum EngineKind { local, openAi, anthropic }

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
  });
  final bool available;
  final String message;
  final List<String> models;
}

class AiRequest {
  const AiRequest({
    required this.model,
    required this.messages,
    required this.systemPrompt,
    required this.cancelToken,
    this.apiKey,
    this.timeout = const Duration(seconds: 120),
  });
  final String model;
  final List<ChatMessage> messages;
  final String systemPrompt;
  final String? apiKey;
  final AiCancelToken cancelToken;
  final Duration timeout;
}

class AiReply {
  const AiReply({
    required this.content,
    required this.model,
    required this.engineLabel,
  });
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
    if (_cancelled)
      throw const AiException('Génération annulée.', cancelled: true);
  }
}
