import '../../core/network/http_json_client.dart';
import '../../domain/ai.dart';

class AnthropicEngine implements AiEngine {
  const AnthropicEngine(this._http);
  final HttpJsonClient _http;
  static final _base = Uri.https('api.anthropic.com', '/v1/');
  @override
  EngineKind get kind => EngineKind.anthropic;
  @override
  String get displayName => 'Anthropic';

  Map<String, String> _headers(String? key) {
    if (key == null || key.trim().isEmpty) {
      throw const AiException(
        'Ajoutez votre clé Anthropic dans les paramètres.',
      );
    }
    return {'x-api-key': key.trim(), 'anthropic-version': '2023-06-01'};
  }

  @override
  Future<EngineProbe> probe({String? apiKey}) async {
    final json = await _http.request(
      'GET',
      _base.resolve('models?limit=100'),
      headers: _headers(apiKey),
    );
    return EngineProbe(
      available: true,
      message: 'API Anthropic accessible.',
      models: modelIds(json, 'data'),
    );
  }

  @override
  Future<AiReply> complete(AiRequest request) async {
    request.cancelToken.throwIfCancelled();
    final json = await _http.request(
      'POST',
      _base.resolve('messages'),
      headers: _headers(request.apiKey),
      body: {
        'model': request.model,
        'system': request.systemPrompt,
        'messages': request.messages
            .map((m) => {'role': m.role.name, 'content': m.content})
            .toList(),
        'max_tokens': 2048,
        'stream': false,
      },
      timeout: request.timeout,
      cancelToken: request.cancelToken,
    );
    final blocks = json['content'];
    if (blocks is! List) {
      throw const AiException('Anthropic a renvoyé une réponse invalide.');
    }
    final content = blocks
        .whereType<Map<String, dynamic>>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'])
        .whereType<String>()
        .join('\n');
    if (content.trim().isEmpty) {
      throw const AiException('Anthropic n’a renvoyé aucun texte exploitable.');
    }
    return AiReply(
      content: content,
      model: json['model'] as String? ?? request.model,
      engineLabel: displayName,
    );
  }
}
