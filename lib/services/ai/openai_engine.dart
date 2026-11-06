import '../../core/network/http_json_client.dart';
import '../../domain/ai.dart';
import 'openai_compatible_engine.dart';

/// Official OpenAI API; no Groq credential is ever sent to this host.
class OpenAiEngine extends OpenAiCompatibleEngine {
  OpenAiEngine(HttpJsonClient http)
    : super(
        kind: EngineKind.openAi,
        displayName: 'OpenAI',
        base: Uri.https('api.openai.com', '/v1/'),
        http: http,
      );
}
