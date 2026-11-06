import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:openus/data/conversation_repository.dart';
import 'package:openus/domain/conversation.dart';

void main() {
  late Directory directory;
  late JsonConversationRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('openus-storage-');
    repository = JsonConversationRepository(directory);
  });
  tearDown(() async { await directory.delete(recursive: true); });
  test('atomic JSON round-trip works on the host filesystem', () async {
    final conversation = Conversation.create().withMessages([ChatMessage.create(role: MessageRole.user, content: 'Bonjour Émile 🚀')]);
    await repository.saveAll([conversation]);
    final restored = await repository.load();
    expect(restored.single.id, conversation.id);
    expect(restored.single.messages.single.content, 'Bonjour Émile 🚀');
    expect(await File('${directory.path}${Platform.pathSeparator}conversations.json.tmp').exists(), isFalse);
  });
  test('corrupt archives are not silently discarded or overwritten', () async {
    final file = File('${directory.path}${Platform.pathSeparator}conversations.json');
    await file.writeAsString('broken json');
    await expectLater(repository.load(), throwsA(isA<StorageFailure>()));
    expect(await file.readAsString(), 'broken json');
  });
  test('serialized concurrent writes leave a valid final archive', () async {
    final first = Conversation.create().withMessages([ChatMessage.create(role: MessageRole.user, content: 'First')]);
    final second = Conversation.create().withMessages([ChatMessage.create(role: MessageRole.user, content: 'Second')]);
    await Future.wait([repository.saveAll([first]), repository.saveAll([first, second])]);
    expect(await repository.load(), hasLength(2));
  });
}
