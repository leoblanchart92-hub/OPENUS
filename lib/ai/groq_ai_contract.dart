import 'ai_provider.dart';
import 'ai_request.dart';
import 'ai_response.dart';

/// Model preset planned exclusively for the future Groq integration.
class GroqModelPreset {
  const GroqModelPreset({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

/// Configuration contract reserved for the future Groq API client.
///
/// No external HTTP client or API key storage is active yet in this phase.
class GroqConfig {
  const GroqConfig({
    this.baseUrl = 'https://api.groq.com/openai/v1',
    this.selectedModelId = defaultModelId,
    this.isEnabled = false,
  });

  static const String defaultModelId = 'llama-3.3-70b-versatile';

  static const List<GroqModelPreset> availablePresets = [
    GroqModelPreset(
      id: 'llama-3.3-70b-versatile',
      label: 'Llama 3.3 70B Versatile',
      description: 'Modèle polyvalent haute précision prévu via Groq.',
    ),
    GroqModelPreset(
      id: 'llama-3.1-8b-instant',
      label: 'Llama 3.1 8B Instant',
      description: 'Réponses ultra-rapides à faible latence via Groq.',
    ),
    GroqModelPreset(
      id: 'mixtral-8x7b-32768',
      label: 'Mixtral 8x7B 32K',
      description: 'Contexte étendu pour synthèses et code via Groq.',
    ),
  ];

  final String baseUrl;
  final String selectedModelId;
  final bool isEnabled;

  GroqConfig copyWith({
    String? baseUrl,
    String? selectedModelId,
    bool? isEnabled,
  }) {
    return GroqConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Future sole cloud provider stub for Groq.
///
/// Intentionally non-operational in Phase 1 so the UI never fakes live cloud
/// inference before explicit Groq API integration.
class GroqAiProviderStub implements AiProviderService {
  const GroqAiProviderStub({this.config = const GroqConfig()});

  final GroqConfig config;

  @override
  String get providerId => 'groq_pending';

  @override
  String get displayName => 'Groq API (Préparé — Non actif)';

  @override
  bool get isLiveCloudProvider => false;

  @override
  Future<AiResponse> generateReply(AiRequest request) {
    throw UnsupportedError(
      'Le fournisseur Groq (${config.selectedModelId}) est préparé dans '
      'l’architecture mais volontairement désactivé dans cette version v1.',
    );
  }
}
