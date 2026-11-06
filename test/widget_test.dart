import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openus/core/network/http_json_client.dart';
import 'package:openus/core/theme/openus_theme.dart';
import 'package:openus/domain/app_settings.dart';
import 'package:openus/domain/conversation.dart';
import 'package:openus/ui/widgets/message_bubble.dart';
import 'package:openus/services/ai/engine_router.dart';
import 'package:openus/services/voice/voice_controller.dart';
import 'package:openus/state/availability_controller.dart';
import 'package:openus/state/conversation_controller.dart';
import 'package:openus/state/settings_controller.dart';
import 'package:openus/data/settings_repository.dart';
import 'package:openus/ui/screens/home_shell.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fakes.dart';

void main() {
  Future<ConversationController> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController(
      repository: SettingsRepository(await SharedPreferences.getInstance()),
      credentials: MemoryCredentials(),
      initial: const AppSettings(reduceMotion: true),
    );
    final repository = MemoryRepository();
    final router = EngineRouter(
      credentials: MemoryCredentials(),
      http: HttpJsonClient(
        () => MockClient((_) async => http.Response('{}', 503)),
      ),
    );
    final availability = AvailabilityController(router, MemoryCredentials());
    final chats = ConversationController(
      repository: repository,
      router: router,
      settings: () => settings.settings,
    );
    await chats.initialize();
    final voice = VoiceController();
    addTearDown(() {
      voice.dispose();
      chats.dispose();
      availability.dispose();
      settings.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: availability),
          ChangeNotifierProvider.value(value: chats),
          ChangeNotifierProvider.value(value: voice),
        ],
        child: MaterialApp(
          theme: OpenUsTheme.build(settings.settings),
          home: const HomeShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return chats;
  }

  testWidgets(
    'desktop foundation renders and settings are accessible without overflow',
    (tester) async {
      await pumpApp(tester, const Size(1280, 900));
      expect(find.text('Bienvenue dans OPENUS.'), findsOneWidget);
      expect(find.text('Moteur non configuré'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Paramètres'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Moteurs IA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'small Android layout opens history and reports no connected engine',
    (tester) async {
      await pumpApp(tester, const Size(360, 740));
      expect(find.text('Bienvenue dans OPENUS.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Ouvrir le menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Conversations'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Vos conversations'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'sending without an engine yields an explicit error, not a simulated reply',
    (tester) async {
      final chats = await pumpApp(tester, const Size(1280, 900));
      await tester.enterText(find.byType(TextField), 'Bonjour OPENUS');
      await tester.tap(find.byTooltip('Envoyer le message'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bonjour OPENUS'), findsOneWidget);
      expect(chats.active!.messages.last.status, MessageStatus.failed);
      expect(chats.active!.messages.last.content, contains('Aucun moteur'));
      final bubbles = tester.widgetList<MessageBubble>(find.byType(MessageBubble)).toList();
      expect(bubbles, hasLength(2));
      expect(bubbles.last.message.content, contains('Aucun moteur'));
      expect(tester.takeException(), isNull);
    },
  );
}
