import 'ai_provider.dart';
import 'ai_request.dart';
import 'ai_response.dart';

/// Local demonstration AI service used during Phase 1 UI/UX & companion design.
///
/// Clearly labels every generated response as simulated demonstration data
/// while exercising the full asynchronous companion animation lifecycle.
class DemoAiService implements AiProviderService {
  DemoAiService({
    this.simulatedDelay = const Duration(milliseconds: 950),
  });

  final Duration simulatedDelay;

  @override
  String get providerId => 'demo_local';

  @override
  String get displayName => 'Mode Démonstration Local';

  @override
  bool get isLiveCloudProvider => false;

  @override
  Future<AiResponse> generateReply(AiRequest request) async {
    final watch = Stopwatch()..start();
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    watch.stop();

    final reply = _buildContextualDemoReply(
      request.prompt,
      request.modelId,
    );

    return AiResponse(
      content: reply,
      modelUsed: 'nexus-demo-v1',
      providerId: providerId,
      isSimulated: true,
      latency: watch.elapsed,
    );
  }

  String _buildContextualDemoReply(String prompt, String? selectedGroqModel) {
    final normalized = prompt.toLowerCase();

    if (normalized.contains('groq') || normalized.contains('api')) {
      final preset = selectedGroqModel ?? 'llama-3.3-70b-versatile';
      return '[Réponse de démonstration]\n'
          'L’architecture Nexus AI est prête pour brancher uniquement l’API Groq '
          '(modèle présélectionné : $preset). Aucun appel réseau n’est effectué '
          'dans cette première version afin de valider d’abord l’interface et '
          'les animations de Nyx.';
    }

    if (normalized.contains('windows') ||
        normalized.contains('flottant') ||
        normalized.contains('compact')) {
      return '[Réponse de démonstration]\n'
          'Sur Windows 10 et 11, vous pouvez passer en Mode Compagnon Compact '
          'depuis la barre latérale ou les paramètres : la fenêtre native '
          's’adapte via MethodChannel (taille compacte, maintien au premier plan '
          'et déplacement libre).';
    }

    if (normalized.contains('nyx') ||
        normalized.contains('compagnon') ||
        normalized.contains('anim')) {
      return '[Réponse de démonstration]\n'
          'Je suis Nyx ! Lorsque vous envoyez un message, je déclenche une '
          'réaction lumineuse, passe en réflexion avec mon anneau orbital, puis '
          'affiche mon onde vocale pendant la réponse. Rendez-vous dans le '
          'Studio Compagnon pour tester chaque expression.';
    }

    if (normalized.contains('android') ||
        normalized.contains('iphone') ||
        normalized.contains('ios') ||
        normalized.contains('mobile')) {
      return '[Réponse de démonstration]\n'
          'Sur Android et iPhone, Nexus AI adapte automatiquement sa navigation '
          'en barre inférieure tactile et garde la zone de saisie visible '
          'au-dessus du clavier virtuel.';
    }

    return '[Réponse de démonstration]\n'
        'Message reçu : « ${prompt.trim()} ».\n'
        'Je fonctionne actuellement avec des données de démonstration locales '
        'pour vous permettre d’explorer l’interface noir & violet néon, la '
        'navigation multiplateforme et les réactions animées de Nyx.';
  }
}
