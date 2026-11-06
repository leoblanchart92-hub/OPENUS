import '../../core/network/http_json_client.dart';
import '../../domain/ai.dart';

/// Shared transport for providers that actually implement the OpenAI chat
/// schema. Provider identity, host and credentials remain separate.
class OpenAiCompatibleEngine implements AiEngine {
  const OpenAiCompatibleEngine({
    required this.kind,
    required this.displayName,
    required Uri base,
    required HttpJsonClient http,
  }) : _base = base,
       _http = http;

  @override
  final EngineKind kind;
  @override
  final String displayName;
  final Uri _base;
  final HttpJsonClient _http;

  Map<String, String> _headers(String? key) {
    if (key == null || key.trim().isEmpty) {
      throw AiException('Ajoutez votre clé $displayName dans les paramètres.');
    }
    return {'authorization': 'Bearer ${key.trim()}'};
  }

  @override
  Future<EngineProbe> probe({String? apiKey}) async {
    final json = await _http.request(
      'GET',
      _base.resolve('models'),
      headers: _headers(apiKey),
    );
    return EngineProbe(
      available: true,
      message: 'API $displayName accessible.',
      models: modelIds(json, 'data'),
    );
  }

  @override
  Future<AiReply> complete(AiRequest request) async {
    request.cancelToken.throwIfCancelled();
    final json = await _http.request(
      'POST',
      _base.resolve('chat/completions'),
      headers: _headers(request.apiKey),
      body: {
        'model': request.model,
        'messages': [
          {'role': 'system', 'content': request.systemPrompt},
          ...request.messages.map(
            (m) => {'role': m.role.name, 'content': m.content},
          ),
        ],
        'max_completion_tokens': request.limits.maxOutputTokens,
        'stream': false,
      },
      timeout: request.timeout,
      cancelToken: request.cancelToken,
    );
    final choices = json['choices'];
    final choice = choices is List ? choices.firstOrNull : null;
    final message = choice is Map<String, dynamic> ? choice['message'] : null;
    final content = message is Map<String, dynamic>
        ? (message['content'] ?? message['refusal'])
        : null;
    if (content is! String || content.trim().isEmpty) {
      throw AiException(
        '$displayName n’a renvoyé aucun texte exploitable. Vérifiez le modèle choisi.',
      );
    }
    return AiReply(
      kind: kind,
      content: content,
      model: json['model'] as String? ?? request.model,
      engineLabel: displayName,
    );
  }
}
