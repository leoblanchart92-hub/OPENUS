import '../../core/network/http_json_client.dart';
import '../../domain/ai.dart';

/// Real Ollama HTTP integration. Ollama itself is NOT bundled or installed.
/// Android localhost means the phone: use a LAN HTTPS/HTTP origin or adb reverse.
class OllamaEngine implements AiEngine {
  OllamaEngine({required String baseUrl, required HttpJsonClient http})
      : _base = baseUrl.trim().replaceAll(RegExp(r'/+$'), ''), _http = http;
  final String _base;
  final HttpJsonClient _http;
  @override
  EngineKind get kind => EngineKind.local;
  @override
  String get displayName => 'Ollama';

  @override
  Future<EngineProbe> probe({String? apiKey}) async {
    final json = await _http.request('GET', Uri.parse('$_base/api/tags'), timeout: const Duration(seconds: 6));
    final models = modelIds(json, 'models');
    return EngineProbe(available: true,
      message: models.isEmpty ? 'Ollama répond, mais aucun modèle n’est installé.' : 'Ollama répond. ${models.length} modèle(s) installé(s).',
      models: models);
  }

  @override
  Future<AiReply> complete(AiRequest request) async {
    request.cancelToken.throwIfCancelled();
    final json = await _http.request('POST', Uri.parse('$_base/api/chat'),
      body: {
        'model': request.model,
        'messages': [
          {'role': 'system', 'content': request.systemPrompt},
          ...request.messages.map((m) => {'role': m.role.name, 'content': m.content}),
        ],
        'stream': false,
      },
      timeout: request.timeout, cancelToken: request.cancelToken,
    );
    final message = json['message'];
    final content = message is Map<String, dynamic> ? message['content'] : null;
    if (content is! String || content.trim().isEmpty) {
      throw const AiException('Ollama n’a renvoyé aucun texte exploitable.');
    }
    return AiReply(content: content, model: json['model'] as String? ?? request.model, engineLabel: displayName);
  }
}
