import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openus/core/network/http_json_client.dart';
import 'package:openus/domain/ai.dart';
import 'package:openus/domain/app_settings.dart';
import 'package:openus/domain/conversation.dart';
import 'package:openus/services/ai/anthropic_engine.dart';
import 'package:openus/services/ai/engine_router.dart';
import 'package:openus/services/ai/ollama_engine.dart';
import 'package:openus/services/ai/openai_engine.dart';
import 'fakes.dart';

void main() {
  test('Ollama sends real chat schema and parses a real response shape', () async {
    late http.Request captured;
    final client = HttpJsonClient(() => MockClient((request) async {
      captured = request;
      return http.Response(jsonEncode({'model': 'local-test', 'message': {'role': 'assistant', 'content': 'Local reply'}}), 200);
    }));
    final engine = OllamaEngine(baseUrl: 'http://127.0.0.1:11434/', http: client);
    final reply = await engine.complete(AiRequest(model: 'local-test', messages: [ChatMessage.create(role: MessageRole.user, content: 'Hello')],
      systemPrompt: 'Be helpful', cancelToken: AiCancelToken()));
    expect(reply.content, 'Local reply'); expect(reply.engineLabel, 'Ollama');
    expect(captured.url.path, '/api/chat');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['stream'], false); expect(body['messages'][0]['role'], 'system');
  });
  test('OpenAI uses bearer auth and never falls back to a generated answer', () async {
    final client = HttpJsonClient(() => MockClient((request) async {
      expect(request.url.toString(), 'https://api.openai.com/v1/chat/completions');
      expect(request.headers['authorization'], 'Bearer test-credential');
      return http.Response('{"choices":[{"message":{"content":"API reply"}}],"model":"test-model"}', 200);
    }));
    final reply = await OpenAiEngine(client).complete(AiRequest(model: 'test-model', apiKey: 'test-credential',
      messages: [ChatMessage.create(role: MessageRole.user, content: 'Hello')], systemPrompt: 'Help', cancelToken: AiCancelToken()));
    expect(reply.content, 'API reply');
    final empty = HttpJsonClient(() => MockClient((_) async => http.Response('{"choices":[]}', 200)));
    expect(OpenAiEngine(empty).complete(AiRequest(model: 'x', apiKey: 'test', messages: [ChatMessage.create(role: MessageRole.user, content: 'Hi')],
      systemPrompt: '', cancelToken: AiCancelToken())), throwsA(isA<AiException>()));
  });
  test('Anthropic uses its own schema and text blocks', () async {
    final client = HttpJsonClient(() => MockClient((request) async {
      expect(request.headers['x-api-key'], 'test-credential');
      expect(request.headers['anthropic-version'], '2023-06-01');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['system'], 'Help'); expect(body['max_tokens'], 2048);
      return http.Response('{"content":[{"type":"text","text":"Claude reply"}]}', 200);
    }));
    final reply = await AnthropicEngine(client).complete(AiRequest(model: 'test-model', apiKey: 'test-credential',
      messages: [ChatMessage.create(role: MessageRole.user, content: 'Hello')], systemPrompt: 'Help', cancelToken: AiCancelToken()));
    expect(reply.content, 'Claude reply');
  });
  test('HTTP errors are sanitized and missing keys never make a request', () async {
    var calls = 0;
    final client = HttpJsonClient(() => MockClient((_) async { calls++; return http.Response('secret reflected', 401); }));
    await expectLater(OpenAiEngine(client).probe(apiKey: 'test-credential'), throwsA(isA<AiException>().having((e) => e.message, 'message', isNot(contains('secret reflected')))));
    await expectLater(OpenAiEngine(client).probe(), throwsA(isA<AiException>()));
    expect(calls, 1);
  });
  test('unconfigured automatic mode does not invent an engine or call the network', () async {
    var calls = 0;
    final router = EngineRouter(credentials: MemoryCredentials(), http: HttpJsonClient(() => MockClient((_) async { calls++; return http.Response('{}', 200); })));
    await expectLater(router.resolve(const AppSettings()), throwsA(isA<AiException>()));
    expect(calls, 0);
  });
  test('automatic mode prefers a genuinely installed local model', () async {
    final router = EngineRouter(credentials: MemoryCredentials()..values[CloudProvider.openAi] = 'test',
      http: HttpJsonClient(() => MockClient((_) async => http.Response('{"models":[{"name":"local-test"}]}', 200))));
    final selection = await router.resolve(const AppSettings(localModel: 'local-test', openAiModel: 'cloud-test'));
    expect(selection.engine.kind, EngineKind.local); expect(selection.model, 'local-test');
    expect(selection.toString(), isNot(contains('test-credential')));
  });
  test('local mode never silently falls back to a configured cloud provider', () async {
    final credentials = MemoryCredentials()..values[CloudProvider.openAi] = 'test';
    final router = EngineRouter(credentials: credentials,
      http: HttpJsonClient(() => MockClient((_) async => http.Response('unavailable', 503))));
    await expectLater(router.resolve(const AppSettings(mode: AiMode.local, localModel: 'local-test', openAiModel: 'cloud-test')), throwsA(isA<AiException>()));
  });
  test('selection toString does not expose its API credential', () {
    final selection = EngineSelection(ScriptedEngine(), 'model', 'sensitive-value');
    expect(selection.toString(), isNot(contains('sensitive-value')));
  });
}
