import '../../data/credential_store.dart';
import '../../domain/ai.dart';
import '../../domain/app_settings.dart';
import '../../domain/conversation.dart';
import '../../core/network/http_json_client.dart';
import '../memory/conversation_context.dart';
import 'anthropic_engine.dart';
import 'ollama_engine.dart';
import 'openai_engine.dart';

class EngineSelection {
  const EngineSelection(this.engine, this.model, this._apiKey);
  final AiEngine engine;
  final String model;
  final String? _apiKey;
  AiRequest request(
    List<ChatMessage> messages,
    String prompt,
    AiCancelToken token,
  ) => AiRequest(
    model: model,
    messages: messages,
    systemPrompt: prompt,
    apiKey: _apiKey,
    cancelToken: token,
  );
  @override
  String toString() => '${engine.displayName} / $model'; // Never expose credentials.
}

class EngineRouter {
  const EngineRouter({
    required this.credentials,
    required this.http,
    this.onProbe,
  });
  final CredentialStore credentials;
  final HttpJsonClient http;
  final void Function(EngineKind, EngineProbe)? onProbe;

  OllamaEngine localEngine(String endpoint) =>
      OllamaEngine(baseUrl: endpoint, http: http);

  AiEngine cloudEngine(CloudProvider provider) => switch (provider) {
    CloudProvider.openAi => OpenAiEngine(http),
    CloudProvider.anthropic => AnthropicEngine(http),
  };

  /// Configuration is not availability. Local availability needs a real probe;
  /// cloud configuration is verified by its test action or the actual chat request.
  Future<EngineSelection> resolve(AppSettings settings) async {
    String? localIssue;
    if (settings.mode != AiMode.internet) {
      if (settings.localConfigured) {
        final engine = OllamaEngine(
          baseUrl: settings.localEndpoint,
          http: http,
        );
        try {
          final probe = await engine.probe();
          onProbe?.call(EngineKind.local, probe);
          if (probe.models.contains(settings.localModel.trim())) {
            return EngineSelection(engine, settings.localModel.trim(), null);
          }
          localIssue =
              'Le modèle local « ${settings.localModel} » n’est pas installé dans Ollama.';
        } on AiException catch (error) {
          localIssue = error.message;
          onProbe?.call(
            EngineKind.local,
            EngineProbe(available: false, message: error.message),
          );
        }
      } else {
        localIssue =
            settings.endpointError ?? 'Choisissez un modèle local installé.';
      }
      if (settings.mode == AiMode.local) throw AiException(localIssue);
    }
    if (settings.mode != AiMode.local && settings.cloudConfigured) {
      final key = await credentials.read(settings.provider);
      if (key != null && key.isNotEmpty) {
        return EngineSelection(
          cloudEngine(settings.provider),
          settings.cloudModel.trim(),
          key,
        );
      }
    }
    if (settings.mode == AiMode.internet) {
      throw const AiException(
        'IA Internet non configurée. Choisissez un modèle et enregistrez une clé API valide.',
      );
    }
    throw AiException(
      settings.mode == AiMode.automatic
          ? 'Aucun moteur disponible. ${localIssue ?? ''} Configurez Ollama ou un fournisseur Internet dans les paramètres.'
          : localIssue ?? 'Aucun moteur configuré.',
    );
  }

  Future<AiReply> complete(
    AppSettings settings,
    Conversation conversation,
    AiCancelToken token,
  ) async {
    final selection = await resolve(settings);
    token.throwIfCancelled();
    final context = ConversationContext.build(
      conversation,
      settings.contextMessages,
    );
    if (context.isEmpty)
      throw const AiException('Le message à envoyer est vide.');
    final reply = await selection.engine.complete(
      selection.request(context, settings.systemPrompt, token),
    );
    token.throwIfCancelled();
    return reply;
  }
}
