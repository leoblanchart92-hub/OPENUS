import '../../core/network/http_json_client.dart';
import '../../domain/ai.dart';
import 'openai_compatible_engine.dart';

/// GroqCloud's documented OpenAI-compatible endpoint. This is a cloud engine:
/// the local 4 GiB target does not apply to models executed by Groq.
class GroqEngine extends OpenAiCompatibleEngine {
  GroqEngine(HttpJsonClient http)
    : super(
        kind: EngineKind.groq,
        displayName: 'Groq',
        base: Uri.https('api.groq.com', '/openai/v1/'),
        http: http,
      );
}
