import '../../core/network/http_json_client.dart';
import '../../domain/ai.dart';
import '../../domain/local_model_profile.dart';

/// Real Ollama HTTP integration. Ollama itself is NOT bundled or installed.
/// Android localhost means the phone: use a LAN HTTPS/HTTP origin or adb reverse.
class OllamaEngine implements AiEngine {
  OllamaEngine({
    required String baseUrl,
    required this._http,
    this.lowMemoryMode = false,
  }) : _base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final String _base;
  final HttpJsonClient _http;
  final bool lowMemoryMode;
  @override
  EngineKind get kind => EngineKind.local;
  @override
  String get displayName => 'Ollama';

  @override
  Future<EngineProbe> probe({String? apiKey}) async {
    final json = await _http.request(
      'GET',
      Uri.parse('$_base/api/tags'),
      timeout: const Duration(seconds: 6),
    );
    final models = modelIds(json, 'models');
    final sizes = <String, int>{};
    final entries = json['models'];
    if (entries is List) {
      for (final entry in entries) {
        if (entry is! Map<String, dynamic>) continue;
        final rawName = entry['name'] ?? entry['model'];
        final name = rawName is String ? rawName : null;
        final size = entry['size'];
        if (name != null && size is int && size >= 0) sizes[name] = size;
      }
    }
    return EngineProbe(
      available: true,
      message: models.isEmpty
          ? 'Ollama répond, mais aucun modèle n’est installé.'
          : 'Ollama répond. ${models.length} modèle(s) installé(s).',
      models: models,
      modelSizesBytes: sizes,
    );
  }

  Map<String, Object> _options(AiRequest request) {
    final options = <String, Object>{
      'num_predict': request.limits.maxOutputTokens,
    };
    final context = request.limits.contextTokens;
    if (context != null) options['num_ctx'] = context;
    if (lowMemoryMode) options['num_batch'] = LocalModelProfile.batchTokens;
    return options;
  }

  @override
  Future<AiReply> complete(AiRequest request) async {
    request.cancelToken.throwIfCancelled();
    final json = await _http.request(
      'POST',
      Uri.parse('$_base/api/chat'),
      body: {
        'model': request.model,
        'messages': [
          {'role': 'system', 'content': request.systemPrompt},
          ...request.messages.map(
            (m) => {'role': m.role.name, 'content': m.content},
          ),
        ],
        'stream': false,
        'options': _options(request),
        if (lowMemoryMode) ...{
          // Immediately release model/KV memory after the reply. The next
          // request pays the reload cost instead of keeping RAM occupied.
          'keep_alive': 0,
          if (LocalModelProfile.supportsThinkingSwitch(request.model))
            'think': false,
        },
      },
      timeout: request.timeout,
      cancelToken: request.cancelToken,
    );
    final message = json['message'];
    final content = message is Map<String, dynamic> ? message['content'] : null;
    if (content is! String || content.trim().isEmpty) {
      throw const AiException('Ollama n’a renvoyé aucun texte exploitable.');
    }
    return AiReply(
      kind: kind,
      content: content,
      model: json['model'] as String? ?? request.model,
      engineLabel: displayName,
    );
  }
}
