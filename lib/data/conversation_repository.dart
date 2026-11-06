import 'dart:convert';
import 'dart:io';
import '../domain/conversation.dart';

class StorageFailure implements Exception {
  const StorageFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract interface class ConversationRepository {
  Future<List<Conversation>> load();
  Future<void> saveAll(List<Conversation> conversations);
}

/// Versioned, private-device JSON storage. Writes are serialized and atomic.
/// No conversations or credentials are sent to an OPENUS server.
class JsonConversationRepository implements ConversationRepository {
  JsonConversationRepository(this.directory);
  final Directory directory;
  Future<void> _writes = Future.value();

  File get _file =>
      File('${directory.path}${Platform.pathSeparator}conversations.json');

  @override
  Future<List<Conversation>> load() async {
    await _writes;
    try {
      if (!await _file.exists()) return [];
      final raw = await _file.readAsString();
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic> ||
          json['schemaVersion'] != 1 ||
          json['conversations'] is! List) {
        throw const FormatException('Unsupported archive');
      }
      final result = (json['conversations'] as List)
          .cast<Map<String, dynamic>>()
          .map(Conversation.fromJson)
          .toList();
      if (result.map((c) => c.id).toSet().length != result.length)
        throw const FormatException('Duplicate IDs');
      return result;
    } on FormatException {
      throw const StorageFailure(
        'Historique illisible. Le fichier existant n’a pas été écrasé ; sauvegardez-le avant de réessayer.',
      );
    } on FileSystemException {
      throw const StorageFailure(
        'Impossible de lire l’historique sur cet appareil. Vérifiez l’espace disque et les permissions.',
      );
    }
  }

  @override
  Future<void> saveAll(List<Conversation> conversations) {
    // Capture a synchronous snapshot: later UI mutations cannot change this write.
    final payload = jsonEncode({
      'schemaVersion': 1,
      'conversations': conversations.map((c) => c.toJson()).toList(),
    });
    final operation = _writes.then((_) => _writeAtomic(payload));
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _writeAtomic(String payload) async {
    final temp = File('${_file.path}.tmp');
    try {
      await directory.create(recursive: true);
      await temp.writeAsString(payload, flush: true);
      // Dart File.rename replaces the destination on supported desktop platforms.
      // Windows File.Replace semantics are covered by the Windows CI smoke test.
      await temp.rename(_file.path);
    } on FileSystemException {
      try {
        if (await temp.exists()) await temp.delete();
      } on FileSystemException {
        /* best effort */
      }
      throw const StorageFailure(
        'Sauvegarde impossible. Vos messages restent en mémoire, mais peuvent être perdus à la fermeture.',
      );
    }
  }
}
