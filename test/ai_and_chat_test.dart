import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ai/ai/ai_provider.dart';
import 'package:nexus_ai/ai/ai_request.dart';
import 'package:nexus_ai/ai/ai_response.dart';
import 'package:nexus_ai/ai/demo_ai_service.dart';
import 'package:nexus_ai/ai/groq_ai_contract.dart';
import 'package:nexus_ai/companion/companion_controller.dart';
import 'package:nexus_ai/core/models/chat_message.dart';
import 'package:nexus_ai/services/chat_service.dart';
import 'package:nexus_ai/settings/settings_controller.dart';

void main() {
  group('AI contracts and ChatService', () {
    test('DemoAiService generates simulated demo responses', () async {
      final service = DemoAiService(simulatedDelay: Duration.zero);
      expect(service.isLiveCloudProvider, isFalse);

      final response = await service.generateReply(
        const AiRequest(
          conversationId: 'c1',
          prompt: 'Comment fonctionne Groq ?',
          history: [],
          modelId: GroqConfig.defaultModelId,
        ),
      );

      expect(response.isSimulated, isTrue);
      expect(response.content, contains('[Réponse de démonstration]'));
      expect(response.content, contains('Groq'));
    });

    test('GroqAiProviderStub stays honestly disabled in v1', () {
      const stub = GroqAiProviderStub();
      expect(stub.isLiveCloudProvider, isFalse);

      expect(
        () => stub.generateReply(
          const AiRequest(
            conversationId: 'c1',
            prompt: 'test',
            history: [],
          ),
        ),
        throwsUnsupportedError,
      );
    });

    for (final action in ['delete', 'reset', 'dispose', 'select', 'error']) {
      test('pending reply handles $action safely', () async {
        final provider = _ControlledProvider();
        final companion = CompanionController();
        final settings = SettingsController(companionController: companion);
        final chat = ChatService(
          aiProvider: provider,
          companionController: companion,
          settingsController: settings,
          speakingShowcaseDuration: Duration.zero,
        );
        final target = chat.createNewConversation();
        final pending = chat.sendMessage('test');
        String? selectedId;
        switch (action) {
          case 'delete':
            chat.deleteConversation(target.id);
          case 'reset':
            chat.resetDemoConversations();
          case 'dispose':
            chat.dispose();
          case 'select':
            selectedId = chat.createNewConversation().id;
          case 'error':
            break;
        }
        if (action == 'error') {
          provider.result.completeError(StateError('simulated failure'));
        } else {
          provider.result.complete(const AiResponse(
            content: 'controlled reply',
            modelUsed: 'test',
            providerId: 'controlled',
            latency: Duration.zero,
            isSimulated: true,
          ));
        }
        await pending;
        if (action == 'delete' || action == 'reset') {
          expect(chat.conversations.any((c) => c.id == target.id), isFalse);
        }
        if (action == 'select') {
          expect(chat.activeConversation?.id, selectedId);
        }
        if (action == 'error') {
          expect(chat.activeConversation!.messages.last.sender,
              MessageSender.system);
          expect(chat.activeConversation!.messages.last.content,
              contains('n’a pas pu être générée'));
        }
        if (action == 'select') {
          final original = chat.conversations.firstWhere((c) => c.id == target.id);
          expect(original.messages.last.content, 'controlled reply');
        }
        if (action != 'dispose') {
          expect(chat.isGenerating, isFalse);
          chat.dispose();
        }
        settings.dispose();
        companion.dispose();
      });
    }

    test('ChatService sends messages and filters demo history', () async {
      final companion = CompanionController();
      final settings = SettingsController(companionController: companion);
      final chat = ChatService(
        aiProvider: DemoAiService(simulatedDelay: Duration.zero),
        companionController: companion,
        settingsController: settings,
        speakingShowcaseDuration: Duration.zero,
      );
      addTearDown(() {
        chat.dispose();
        settings.dispose();
        companion.dispose();
      });

      expect(chat.conversations.length, greaterThanOrEqualTo(3));

      final created = chat.createNewConversation(title: 'Test Unitaire');
      expect(chat.activeConversation?.id, created.id);

      await chat.sendMessage('Bonjour Nyx');
      final messages = chat.activeConversation!.messages;
      expect(messages.length, 3);
      expect(messages[1].isUser, isTrue);
      expect(messages[1].content, 'Bonjour Nyx');
      expect(messages[2].isAssistant, isTrue);
      expect(messages[2].isDemo, isTrue);

      final filtered = chat.filterConversations('Windows');
      expect(filtered, isNotEmpty);

      chat.deleteConversation(created.id);
      expect(
        chat.conversations.any((c) => c.id == created.id),
        isFalse,
      );
    });
  });
}

class _ControlledProvider implements AiProviderService {
  final Completer<AiResponse> result = Completer<AiResponse>();

  @override
  String get providerId => 'controlled';

  @override
  String get displayName => 'Controlled test provider';

  @override
  bool get isLiveCloudProvider => false;

  @override
  Future<AiResponse> generateReply(AiRequest request) => result.future;
}
