import 'package:flutter_test/flutter_test.dart';
import 'package:openus/domain/ai.dart';
import 'package:openus/domain/app_settings.dart';
import 'package:openus/domain/conversation.dart';
import 'package:openus/services/memory/conversation_context.dart';

void main() {
  test('settings round-trip contains preferences and no credential fields', () {
    const settings = AppSettings(
      mode: AiMode.local,
      localModel: 'installed-model',
      accent: AccentChoice.blue,
      speechRate: .4,
    );
    final json = settings.toJson();
    final restored = AppSettings.fromJson(json);
    expect(restored.mode, AiMode.local);
    expect(restored.localModel, 'installed-model');
    expect(restored.accent, AccentChoice.blue);
    expect(restored.speechRate, .4);
    expect(
      json.keys.any(
        (k) =>
            k.toLowerCase().contains('key') ||
            k.toLowerCase().contains('secret'),
      ),
      isFalse,
    );
  });
  test('unknown settings and out-of-range values are safe', () {
    final s = AppSettings.fromJson({
      'mode': 'unknown',
      'contextMessages': 500,
      'speechRate': -2,
    });
    expect(s.mode, AiMode.automatic);
    expect(s.contextMessages, 40);
    expect(s.speechRate, .3);
    expect(s.openAiModel, isEmpty);
    expect(s.localModel, isEmpty);
  });
  test(
    'local origins allowed, public cleartext and credential URLs rejected',
    () {
      for (final endpoint in [
        'http://127.0.0.1:11434',
        'http://10.0.2.2:11434',
        'http://192.168.1.20:11434',
        'http://localhost:11434',
        'https://example.com',
      ]) {
        expect(
          AppSettings(localEndpoint: endpoint).endpointError,
          isNull,
          reason: endpoint,
        );
      }
      for (final endpoint in [
        'http://example.com',
        'http://user:password@localhost:11434',
        'file:///tmp',
        'http://localhost:11434/api',
        'http://localhost?key=value',
      ]) {
        expect(
          AppSettings(localEndpoint: endpoint).endpointError,
          isNotNull,
          reason: endpoint,
        );
      }
    },
  );
  test('context is bounded, excludes failures and starts with a user turn', () {
    final conversation = Conversation.create().withMessages([
      ChatMessage.create(role: MessageRole.assistant, content: 'Old answer'),
      ChatMessage.create(role: MessageRole.user, content: 'Question'),
      ChatMessage.create(
        role: MessageRole.assistant,
        content: '',
        status: MessageStatus.pending,
      ),
      ChatMessage.create(
        role: MessageRole.assistant,
        content: 'Error',
        status: MessageStatus.failed,
      ),
      ChatMessage.create(role: MessageRole.user, content: 'New question'),
    ]);
    final context = ConversationContext.build(conversation, 4);
    expect(context.map((m) => m.content), ['Question', 'New question']);
    expect(ConversationContext.build(Conversation.create(), 20), isEmpty);
  });
  test('pending replies become cancelled after deserialization', () {
    final message = ChatMessage.create(
      role: MessageRole.assistant,
      content: '',
      status: MessageStatus.pending,
    );
    expect(
      ChatMessage.fromJson(message.toJson()).status,
      MessageStatus.cancelled,
    );
  });
  test('cancellation notifies once and supports late listeners', () {
    final token = AiCancelToken();
    var count = 0;
    token.addListener(() => count++);
    token.cancel();
    token.cancel();
    token.addListener(() => count++);
    expect(count, 2);
    expect(token.isCancelled, isTrue);
    expect(token.throwIfCancelled, throwsA(isA<AiException>()));
  });
}
