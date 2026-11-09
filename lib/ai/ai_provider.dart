import 'ai_request.dart';
import 'ai_response.dart';

/// Contract implemented by all AI backends in Nexus AI.
///
/// Phase 1 uses [DemoAiService] for deterministic demo exchanges.
/// Phase 2 will activate [GroqAiProviderStub] as the sole cloud AI provider.
abstract class AiProviderService {
  String get providerId;
  String get displayName;
  bool get isLiveCloudProvider;

  Future<AiResponse> generateReply(AiRequest request);
}
