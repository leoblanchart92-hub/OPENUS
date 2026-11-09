import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ai/ai_provider.dart';
import '../ai/ai_request.dart';
import '../companion/companion_controller.dart';
import '../companion/companion_state.dart';
import '../core/models/chat_message.dart';
import '../core/models/conversation.dart';
import '../data/demo_conversations.dart';
import '../settings/settings_controller.dart';

/// Coordinates conversation state, demo persistence, and companion animation
/// lifecycle while delegating replies to an [AiProviderService].
class ChatService extends ChangeNotifier {
  ChatService({
    required AiProviderService aiProvider,
    required CompanionController companionController,
    required SettingsController settingsController,
    List<Conversation>? initialConversations,
    this.speakingShowcaseDuration = const Duration(milliseconds: 1200),
  })  : _aiProvider = aiProvider,
        _companionController = companionController,
        _settingsController = settingsController,
        _conversations = List<Conversation>.from(
          initialConversations ?? DemoConversations.createInitial(),
        ) {
    if (_conversations.isNotEmpty) {
      _activeConversationId = _conversations.first.id;
    }
    // Restored upgrade checkpoints must not collide with new message IDs.
    for (final conversation in _conversations) {
      for (final id in [conversation.id, ...conversation.messages.map((m) => m.id)]) {
        final suffix = int.tryParse(id.split('-').last);
        if (suffix != null && suffix > _idCounter) {
          _idCounter = suffix;
        }
      }
    }
  }

  final AiProviderService _aiProvider;
  final CompanionController _companionController;
  final SettingsController _settingsController;
  final Duration speakingShowcaseDuration;

  List<Conversation> _conversations;
  String? _activeConversationId;
  bool _isGenerating = false;
  bool _disposed = false;
  Timer? _speakingFinishTimer;
  int _idCounter = 100;
  int _requestGeneration = 0;

  AiProviderService get aiProvider => _aiProvider;
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  bool get isGenerating => _isGenerating;

  Conversation? get activeConversation {
    if (_conversations.isEmpty) {
      return null;
    }
    for (final conv in _conversations) {
      if (conv.id == _activeConversationId) {
        return conv;
      }
    }
    return _conversations.first;
  }

  String _nextId(String prefix) {
    _idCounter++;
    return '$prefix-$_idCounter';
  }

  void selectConversation(String conversationId) {
    if (_activeConversationId == conversationId) {
      return;
    }
    _activeConversationId = conversationId;
    notifyListeners();
  }

  Conversation createNewConversation({String? title}) {
    final id = _nextId('demo-conv');
    final created = Conversation(
      id: id,
      title: title ?? 'Nouvelle discussion démo',
      topicTag: 'Démo • Nouvelle',
      updatedAt: DateTime.now(),
      isDemo: true,
      messages: [
        ChatMessage(
          id: _nextId('msg'),
          sender: MessageSender.assistant,
          content:
              'Nouvelle session de démonstration ouverte. Posez une question '
              'ou testez un message pour observer la réaction de Nyx.',
          timestamp: DateTime.now(),
          isDemo: true,
          providerLabel: _aiProvider.displayName,
        ),
      ],
    );
    _conversations = [created, ..._conversations];
    _activeConversationId = created.id;
    notifyListeners();
    return created;
  }

  void deleteConversation(String conversationId) {
    _conversations = _conversations
        .where((conv) => conv.id != conversationId)
        .toList(growable: false);
    if (_activeConversationId == conversationId) {
      _activeConversationId =
          _conversations.isNotEmpty ? _conversations.first.id : null;
    }
    notifyListeners();
  }

  void resetDemoConversations() {
    _requestGeneration++;
    _companionController.setState(CompanionState.idle);
    _speakingFinishTimer?.cancel();
    _speakingFinishTimer = null;
    _isGenerating = false;
    _conversations = DemoConversations.createInitial();
    _activeConversationId =
        _conversations.isNotEmpty ? _conversations.first.id : null;
    notifyListeners();
  }

  List<Conversation> filterConversations(String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return conversations;
    }
    return _conversations.where((conv) {
      if (conv.title.toLowerCase().contains(trimmed) ||
          conv.topicTag.toLowerCase().contains(trimmed)) {
        return true;
      }
      return conv.messages.any(
        (m) => m.content.toLowerCase().contains(trimmed),
      );
    }).toList(growable: false);
  }

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (_disposed || text.isEmpty || _isGenerating) {
      return;
    }

    var target = activeConversation;
    target ??= createNewConversation(title: _deriveTitle(text));

    final userMessage = ChatMessage(
      id: _nextId('usr'),
      sender: MessageSender.user,
      content: text,
      timestamp: DateTime.now(),
      isDemo: true,
      providerLabel: 'Utilisateur',
    );

    final shouldAutoTitle = target.messages.length <= 1 &&
        target.title.startsWith('Nouvelle discussion');
    final updatedTitle = shouldAutoTitle ? _deriveTitle(text) : target.title;

    _replaceConversation(
      target.copyWith(
        title: updatedTitle,
        updatedAt: DateTime.now(),
        messages: [...target.messages, userMessage],
      ),
    );

    final generation = ++_requestGeneration;
    _speakingFinishTimer?.cancel();
    _isGenerating = true;
    notifyListeners();

    // 1. Companion immediate reaction -> thinking
    _companionController.triggerMessageSentReaction();

    try {
      final response = await _aiProvider.generateReply(
        AiRequest(
          conversationId: target.id,
          prompt: text,
          history: target.messages,
          modelId: _settingsController.settings.preferredGroqModelId,
        ),
      );

      if (_disposed || generation != _requestGeneration) {
        return;
      }

      final latest = _findById(target.id);
      if (latest == null) {
        _companionController.triggerResponseFinished();
        return;
      }

      // 2. Companion speaking animation while delivering reply
      _companionController.triggerResponseStarted();

      final assistantMessage = ChatMessage(
        id: _nextId('ai'),
        sender: MessageSender.assistant,
        content: response.content,
        timestamp: DateTime.now(),
        isDemo: response.isSimulated,
        providerLabel: _aiProvider.displayName,
      );

      final selectedId = _activeConversationId;
      _replaceConversation(
        latest.copyWith(
          updatedAt: DateTime.now(),
          messages: [...latest.messages, assistantMessage],
        ),
      );

      _activeConversationId = selectedId;

      _speakingFinishTimer?.cancel();
      if (speakingShowcaseDuration == Duration.zero) {
        _companionController.triggerResponseFinished();
      } else {
        _speakingFinishTimer = Timer(speakingShowcaseDuration, () {
          if (!_disposed) {
            _companionController.triggerResponseFinished();
          }
        });
      }
    } catch (_) {
      if (!_disposed && generation == _requestGeneration) {
        _companionController.triggerResponseFinished();
        final latest = _findById(target.id);
        if (latest != null) {
          final selectedId = _activeConversationId;
          _replaceConversation(latest.copyWith(
            updatedAt: DateTime.now(),
            messages: [
              ...latest.messages,
              ChatMessage(
                id: _nextId('error'),
                sender: MessageSender.system,
                content: 'La réponse n’a pas pu être générée. Réessayez.',
                timestamp: DateTime.now(),
              ),
            ],
          ));
          _activeConversationId = selectedId;
        }
      }
    } finally {
      if (!_disposed && generation == _requestGeneration) {
        _isGenerating = false;
        notifyListeners();
      }
    }
  }

  Conversation? _findById(String id) {
    for (final conv in _conversations) {
      if (conv.id == id) {
        return conv;
      }
    }
    return null;
  }

  void _replaceConversation(Conversation updated) {
    final others = _conversations.where((c) => c.id != updated.id).toList();
    _conversations = [updated, ...others];
    _activeConversationId = updated.id;
  }

  String _deriveTitle(String prompt) {
    final cleaned = prompt.replaceAll('\n', ' ').trim();
    if (cleaned.length <= 36) {
      return cleaned;
    }
    return '${cleaned.substring(0, 33)}...';
  }

  @override
  void dispose() {
    _disposed = true;
    _speakingFinishTimer?.cancel();
    _speakingFinishTimer = null;
    super.dispose();
  }
}
