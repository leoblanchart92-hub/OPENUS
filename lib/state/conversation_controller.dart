import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/app_info.dart';
import '../data/conversation_repository.dart';
import '../domain/ai.dart';
import '../domain/app_settings.dart';
import '../domain/conversation.dart';
import '../services/ai/engine_router.dart';

class ConversationController extends ChangeNotifier {
  ConversationController({
    required ConversationRepository repository,
    required EngineRouter router,
    required AppSettings Function() settings,
    this.onEngineSuccess,
  }) : _repository = repository,
       _router = router,
       _settings = settings;
  final ConversationRepository _repository;
  final EngineRouter _router;
  final AppSettings Function() _settings;
  final void Function(EngineKind)? onEngineSuccess;
  final List<Conversation> _conversations = [];
  String? _activeId;
  AiCancelToken? _cancelToken;
  bool _loading = true;
  bool _generating = false;
  bool _disposed = false;
  bool _archiveUnreadable = false;
  String? _storageNotice;

  List<Conversation> get conversations =>
      List.unmodifiable(_conversations.reversed);
  Conversation? get active =>
      _conversations.where((c) => c.id == _activeId).firstOrNull;
  bool get loading => _loading;
  bool get generating => _generating;
  String? get storageNotice => _storageNotice;

  Future<void> initialize() async {
    try {
      final stored = await _repository.load();
      _conversations.addAll(stored.where((c) => c.messages.isNotEmpty));
      _sort();
    } on StorageFailure catch (error) {
      _archiveUnreadable = true;
      _storageNotice = error.message;
    } catch (_) {
      _archiveUnreadable = true;
      _storageNotice =
          'Historique indisponible. Cet appareil n’a pas pu ouvrir le stockage local.';
    }
    if (_conversations.isEmpty) _conversations.add(Conversation.create());
    _activeId = _conversations.first.id;
    _loading = false;
    _notify();
  }

  void _sort() =>
      _conversations.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
  void _upsert(Conversation conversation) {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index < 0) {
      _conversations.add(conversation);
    } else {
      _conversations[index] = conversation;
    }
    _sort();
  }

  void newConversation() {
    if (_loading) return;
    if (active != null && active!.messages.isEmpty) return;
    final conversation = Conversation.create();
    _conversations.add(conversation);
    _activeId = conversation.id;
    _notify();
  }

  void select(String id) {
    if (_conversations.any((c) => c.id == id)) {
      _activeId = id;
      _notify();
    }
  }

  Future<String?> send(String input) async {
    if (_generating || _loading || _disposed) return null;
    final text = input.trim();
    if (text.isEmpty ||
        text.length > AppInfo.maxMessageLength ||
        active == null) {
      return null;
    }
    final snapshot = _settings();
    final token = AiCancelToken();
    _cancelToken = token;
    _generating = true;
    final user = ChatMessage.create(role: MessageRole.user, content: text);
    final pending = ChatMessage.create(
      role: MessageRole.assistant,
      content: '',
      status: MessageStatus.pending,
    );
    var conversation = active!.withMessages([
      ...active!.messages,
      user,
      pending,
    ]);
    _upsert(conversation);
    _notify();
    unawaited(_persist());
    try {
      final reply = await _router.complete(snapshot, conversation, token);
      if (_disposed) return null;
      _updateMessage(
        conversation.id,
        pending.copyWith(
          content: reply.content,
          status: MessageStatus.completed,
          engineLabel: '${reply.engineLabel} · ${reply.model}',
        ),
      );
      onEngineSuccess?.call(_kind(reply.engineLabel));
      unawaited(_persist());
      return reply.content;
    } catch (error) {
      if (token.isCancelled) {
        _updateMessage(
          conversation.id,
          pending.copyWith(
            status: MessageStatus.cancelled,
            content: 'Génération annulée. Aucun texte IA n’a été conservé.',
          ),
        );
      } else {
        final message = error is AiException
            ? error.message
            : 'La requête a échoué. Vérifiez la configuration et le stockage sécurisé.';
        _updateMessage(
          conversation.id,
          pending.copyWith(
            status: MessageStatus.failed,
            content: message,
            error: message,
          ),
        );
      }
      unawaited(_persist());
      return null;
    } finally {
      _generating = false;
      _cancelToken = null;
      _notify();
    }
  }

  EngineKind _kind(String label) => label == 'Ollama'
      ? EngineKind.local
      : label == 'OpenAI'
      ? EngineKind.openAi
      : EngineKind.anthropic;

  void cancelGeneration() => _cancelToken?.cancel();

  void _updateMessage(String conversationId, ChatMessage message) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0 || _disposed) {
      return; // A late response must not recreate deleted data.
    }
    final old = _conversations[index];
    if (!old.messages.any((m) => m.id == message.id)) return;
    _upsert(
      old.withMessages(
        old.messages.map((m) => m.id == message.id ? message : m).toList(),
      ),
    );
    _notify();
  }

  Future<void> _persist() async {
    if (_archiveUnreadable) {
      _storageNotice =
          'Historique non sauvegardé : le fichier existant est illisible. Les nouveaux messages restent en mémoire.';
      _notify();
      return;
    }
    try {
      await _repository.saveAll(
        _conversations.where((c) => c.messages.isNotEmpty).toList(),
      );
      _storageNotice = null;
    } on StorageFailure catch (error) {
      _storageNotice = error.message;
    } catch (_) {
      _storageNotice =
          'Sauvegarde locale impossible. Les messages restent uniquement en mémoire.';
    }
    _notify();
  }

  Future<bool> delete(String id) async {
    if (_generating && id == _activeId) cancelGeneration();
    final remaining = _conversations
        .where((c) => c.id != id && c.messages.isNotEmpty)
        .toList();
    try {
      await _repository.saveAll(remaining);
      _conversations.removeWhere((c) => c.id == id);
      _archiveUnreadable = false;
      _storageNotice = null;
      if (_activeId == id || _conversations.isEmpty) {
        final fresh = Conversation.create();
        _conversations.add(fresh);
        _activeId = fresh.id;
      }
      _notify();
      return true;
    } catch (_) {
      _storageNotice =
          'Suppression impossible sur le disque. La conversation n’a pas été supprimée.';
      _notify();
      return false;
    }
  }

  Future<bool> clear() async {
    cancelGeneration();
    try {
      await _repository.saveAll(const []);
      final fresh = Conversation.create();
      _conversations
        ..clear()
        ..add(fresh);
      _activeId = fresh.id;
      _archiveUnreadable = false;
      _storageNotice = null;
      _notify();
      return true;
    } catch (_) {
      _storageNotice = 'L’historique n’a pas pu être effacé sur le disque.';
      _notify();
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelToken?.cancel();
    super.dispose();
  }
}
