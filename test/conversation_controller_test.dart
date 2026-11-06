import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openus/core/network/http_json_client.dart';
import 'package:openus/domain/app_settings.dart';
import 'package:openus/domain/conversation.dart';
import 'package:openus/services/ai/engine_router.dart';
import 'package:openus/state/conversation_controller.dart';
import 'fakes.dart';

void main() {
  late MemoryRepository repository;
  late ConversationController controller;
  setUp(() async {
    repository = MemoryRepository();
    final router = EngineRouter(
      credentials: MemoryCredentials(),
      http: HttpJsonClient(
        () => MockClient((_) async => http.Response('{}', 503)),
      ),
    );
    controller = ConversationController(
      repository: repository,
      router: router,
      settings: () => const AppSettings(),
    );
    await controller.initialize();
  });
  tearDown(() => controller.dispose());

  test(
    'unconfigured send preserves the question and an explicit failure, never fake AI',
    () async {
      final result = await controller.send('Bonjour');
      expect(result, isNull);
      expect(controller.active!.messages, hasLength(2));
      expect(controller.active!.messages.first.content, 'Bonjour');
      expect(controller.active!.messages.last.status, MessageStatus.failed);
      expect(
        controller.active!.messages.last.content,
        contains('Aucun moteur'),
      );
      expect(controller.generating, isFalse);
    },
  );
  test('blank input is ignored and new conversations are distinct', () async {
    await controller.send('  ');
    expect(controller.active!.messages, isEmpty);
    final first = controller.active!.id;
    await controller.send('Question');
    controller.newConversation();
    expect(controller.active!.id, isNot(first));
    expect(controller.active!.messages, isEmpty);
    controller.select(first);
    expect(controller.active!.title, 'Question');
  });
  test(
    'delete removes persisted data and late responses cannot resurrect it',
    () async {
      await controller.send('Private question');
      final id = controller.active!.id;
      expect(await controller.delete(id), isTrue);
      expect(repository.saved, isEmpty);
      expect(controller.active!.id, isNot(id));
      expect(await controller.clear(), isTrue);
      expect(controller.conversations.single.messages, isEmpty);
    },
  );
  test(
    'disk failure keeps messages in memory and surfaces a warning',
    () async {
      repository.failWrites = true;
      await controller.send('Keep this');
      await Future<void>.delayed(Duration.zero);
      expect(controller.active!.messages.first.content, 'Keep this');
      expect(controller.storageNotice, isNotNull);
      expect(repository.saved, isEmpty);
    },
  );
}
