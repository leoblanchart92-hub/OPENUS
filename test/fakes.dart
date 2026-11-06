import 'package:openus/data/conversation_repository.dart';
import 'package:openus/data/credential_store.dart';
import 'package:openus/domain/ai.dart';
import 'package:openus/domain/conversation.dart';

// Test doubles stay under test/: production has no simulated AI engine.
class MemoryRepository implements ConversationRepository {
  List<Conversation> saved = [];
  bool failWrites = false;
  int writes = 0;
  @override
  Future<List<Conversation>> load() async =>
      saved.map((c) => Conversation.fromJson(c.toJson())).toList();
  @override
  Future<void> saveAll(List<Conversation> conversations) async {
    if (failWrites) throw const StorageFailure('Disk unavailable');
    writes++;
    saved = conversations.map((c) => Conversation.fromJson(c.toJson())).toList();
  }
}

class MemoryCredentials implements CredentialStore {
  final Map<CloudProvider, String> values = {};
  @override
  Future<String?> read(CloudProvider provider) async => values[provider];
  @override
  Future<void> save(CloudProvider provider, String key) async {
    values[provider] = key;
  }

  @override
  Future<void> delete(CloudProvider provider) async {
    values.remove(provider);
  }
}

class ScriptedEngine implements AiEngine {
  ScriptedEngine({
    this.kind = EngineKind.openAi,
    this.available = true,
    this.models = const ['test-model'],
  });
  @override
  final EngineKind kind;
  final bool available;
  final List<String> models;
  int calls = 0;
  @override
  String get displayName => 'Test engine';
  @override
  Future<EngineProbe> probe({String? apiKey}) async =>
      EngineProbe(available: available, message: 'Test probe', models: models);
  @override
  Future<AiReply> complete(AiRequest request) async {
    calls++;
    request.cancelToken.throwIfCancelled();
    return AiReply(
      content: 'Engine result',
      model: request.model,
      engineLabel: displayName,
    );
  }
}
