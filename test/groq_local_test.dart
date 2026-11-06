import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openus/core/network/http_json_client.dart';
import 'package:openus/domain/ai.dart';
import 'package:openus/domain/app_settings.dart';
import 'package:openus/domain/conversation.dart';
import 'package:openus/domain/local_model_profile.dart';
import 'package:openus/services/ai/engine_router.dart';
import 'package:openus/services/ai/groq_engine.dart';
import 'package:openus/services/ai/ollama_engine.dart';
import 'fakes.dart';

void main() {
  test('Groq uses its official host, bearer key and chat schema', () async {
    final requests = <http.Request>[];
    final client = HttpJsonClient(
      () => MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response('{"data":[{"id":"llama-3.1-8b-instant"}]}', 200);
        }
        return http.Response(
          '{"choices":[{"message":{"content":"Groq reply"}}],"model":"llama-3.1-8b-instant"}',
          200,
        );
      }),
    );
    final engine = GroqEngine(client);
    final probe = await engine.probe(apiKey: 'test-only-credential');
    expect(probe.available, isTrue);
    expect(probe.models, contains('llama-3.1-8b-instant'));
    final reply = await engine.complete(
      AiRequest(
        model: 'llama-3.1-8b-instant',
        apiKey: 'test-only-credential',
        messages: [
          ChatMessage.create(role: MessageRole.user, content: 'Bonjour'),
        ],
        systemPrompt: 'Aide',
        cancelToken: AiCancelToken(),
      ),
    );
    expect(reply.kind, EngineKind.groq);
    expect(reply.content, 'Groq reply');
    expect(
      requests.first.url.toString(),
      'https://api.groq.com/openai/v1/models',
    );
    expect(
      requests.last.url.toString(),
      'https://api.groq.com/openai/v1/chat/completions',
    );
    expect(
      requests.last.headers['authorization'],
      'Bearer test-only-credential',
    );
    final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
    expect(body['model'], 'llama-3.1-8b-instant');
    expect(body['stream'], false);
    expect(body['max_completion_tokens'], 2048);
    expect(body['messages'][0]['role'], 'system');
    expect(reply.toString(), isNot(contains('test-only-credential')));
  });

  test(
    'Groq missing key and HTTP errors never fabricate or leak data',
    () async {
      var calls = 0;
      final client = HttpJsonClient(
        () => MockClient((_) async {
          calls++;
          return http.Response('test-only-credential reflected', 429);
        }),
      );
      await expectLater(
        GroqEngine(client).probe(),
        throwsA(isA<AiException>()),
      );
      expect(calls, 0);
      await expectLater(
        GroqEngine(client).probe(apiKey: 'test-only-credential'),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            allOf(contains('429'), isNot(contains('test-only-credential'))),
          ),
        ),
      );
      expect(calls, 1);
    },
  );

  test(
    'Internet Groq routing never probes Ollama and keeps keys isolated',
    () async {
      final credentials = MemoryCredentials()
        ..values[CloudProvider.groq] = 'groq-test-only';
      final hosts = <String>[];
      final router = EngineRouter(
        credentials: credentials,
        http: HttpJsonClient(
          () => MockClient((request) async {
            hosts.add(request.url.host);
            expect(request.headers['authorization'], 'Bearer groq-test-only');
            return http.Response(
              '{"choices":[{"message":{"content":"Cloud reply"}}]}',
              200,
            );
          }),
        ),
      );
      const settings = AppSettings(
        mode: AiMode.internet,
        provider: CloudProvider.groq,
        groqModel: 'llama-3.1-8b-instant',
        localModel: LocalModelProfile.recommendedModel,
        openAiModel: 'openai-model',
        anthropicModel: 'anthropic-model',
      );
      final selection = await router.resolve(settings);
      expect(selection.engine.kind, EngineKind.groq);
      expect(selection.model, 'llama-3.1-8b-instant');
      expect(selection.toString(), isNot(contains('groq-test-only')));
      final conversation = Conversation.create().withMessages([
        ChatMessage.create(role: MessageRole.user, content: 'Bonjour'),
      ]);
      final reply = await router.complete(
        settings,
        conversation,
        AiCancelToken(),
      );
      expect(reply.kind, EngineKind.groq);
      expect(hosts, everyElement('api.groq.com'));
      expect(credentials.values[CloudProvider.openAi], isNull);
      expect(credentials.values[CloudProvider.anthropic], isNull);
    },
  );

  test(
    'local mode with Groq configured still refuses cloud fallback',
    () async {
      final credentials = MemoryCredentials()
        ..values[CloudProvider.groq] = 'groq-test-only';
      final hosts = <String>[];
      final router = EngineRouter(
        credentials: credentials,
        http: HttpJsonClient(
          () => MockClient((request) async {
            hosts.add(request.url.host);
            return http.Response('unavailable', 503);
          }),
        ),
      );
      await expectLater(
        router.resolve(
          const AppSettings(
            mode: AiMode.local,
            localModel: LocalModelProfile.recommendedModel,
            provider: CloudProvider.groq,
            groqModel: 'llama-3.1-8b-instant',
          ),
        ),
        throwsA(isA<AiException>()),
      );
      expect(hosts, isNot(contains('api.groq.com')));
    },
  );

  test('light Ollama profile bounds context/batch/output and unloads', () async {
    late http.Request captured;
    final client = HttpJsonClient(
      () => MockClient((request) async {
        captured = request;
        return http.Response(
          '{"message":{"content":"Local reply"},"model":"${LocalModelProfile.recommendedModel}"}',
          200,
        );
      }),
    );
    final reply =
        await OllamaEngine(
          baseUrl: 'http://127.0.0.1:11434',
          http: client,
          lowMemoryMode: true,
        ).complete(
          AiRequest(
            model: LocalModelProfile.recommendedModel,
            messages: [
              ChatMessage.create(role: MessageRole.user, content: 'Bonjour'),
            ],
            systemPrompt: 'Aide',
            limits: const GenerationLimits(
              maxOutputTokens: LocalModelProfile.outputTokens,
              contextTokens: LocalModelProfile.contextTokens,
            ),
            cancelToken: AiCancelToken(),
          ),
        );
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(reply.kind, EngineKind.local);
    expect(body['keep_alive'], 0);
    expect(body['think'], false);
    expect(body['options']['num_ctx'], 2048);
    expect(body['options']['num_batch'], 128);
    expect(body['options']['num_predict'], 512);
  });

  test(
    'router accepts the light preset but rejects known oversized weights',
    () async {
      EngineRouter routerWithSize(int size) => EngineRouter(
        credentials: MemoryCredentials(),
        http: HttpJsonClient(
          () => MockClient(
            (_) async => http.Response(
              jsonEncode({
                'models': [
                  {'name': LocalModelProfile.recommendedModel, 'size': size},
                ],
              }),
              200,
            ),
          ),
        ),
      );
      final settings = const AppSettings(
        mode: AiMode.local,
      ).withLightLocalPreset();
      final selection = await routerWithSize(523000000).resolve(settings);
      expect(selection.engine.kind, EngineKind.local);
      expect(selection.limits.contextTokens, 2048);
      expect(selection.limits.maxOutputTokens, 512);
      await expectLater(
        routerWithSize(3 * 1024 * 1024 * 1024).resolve(settings),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            contains('profil léger'),
          ),
        ),
      );
    },
  );
}
