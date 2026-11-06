import '../../core/network/http_json_client.dart';
import '../../domain/ai.dart';

/// Official OpenAI API. A different provider requires a different adapter,
/// rather than conditionals scattered through the UI or conversation controller.
class OpenAiEngine implements AiEngine {
  const OpenAiEngine(this._http);
  final HttpJsonClient _http;
  static final _base = Uri.https('api.openai.com', '/v1/');
  @override
  EngineKind get kind => EngineKind.openAi;
  @override
  String get displayName => 'OpenAI';

  Map<String, String> _headers(String? key) {
    if (key == null || key.trim().isEmpty) {
      throw const AiException('Ajoutez votre clé OpenAI dans les paramètres.');
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
      message: 'API OpenAI accessible.',
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
        'max_completion_tokens': 2048,
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
      throw const AiException(
        'OpenAI n’a renvoyé aucun texte exploitable. Vérifiez le modèle choisi.',
      );
    }
    return AiReply(
      content: content,
      model: json['model'] as String? ?? request.model,
      engineLabel: displayName,
    );
  }
}
