import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openus/core/network/http_json_client.dart';
import 'package:openus/core/theme/openus_theme.dart';
import 'package:openus/domain/ai.dart';
import 'package:openus/domain/app_settings.dart';
import 'package:openus/domain/local_model_profile.dart';
import 'package:openus/data/settings_repository.dart';
import 'package:openus/services/ai/engine_router.dart';
import 'package:openus/state/availability_controller.dart';
import 'package:openus/state/settings_controller.dart';
import 'package:openus/ui/screens/settings/engine_settings_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fakes.dart';

void main() {
  testWidgets('mobile settings save an isolated Groq key and light preset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final credentials = MemoryCredentials();
    final settings = SettingsController(
      repository: SettingsRepository(await SharedPreferences.getInstance()),
      credentials: credentials,
      initial: const AppSettings(reduceMotion: true),
    );
    final router = EngineRouter(
      credentials: credentials,
      http: HttpJsonClient(
        () => MockClient((_) async => http.Response('{}', 503)),
      ),
    );
    final availability = AvailabilityController(router, credentials);
    addTearDown(() {
      availability.dispose();
      settings.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: availability),
        ],
        child: MaterialApp(
          theme: OpenUsTheme.build(settings.settings),
          home: const Scaffold(body: EngineSettingsPage()),
        ),
      ),
    );
    await tester.pump();

    final groq = find.byKey(const ValueKey('provider-groq'));
    await tester.ensureVisible(groq);
    await tester.pump();
    await tester.tap(groq);
    await tester.pump();
    final model = tester.widget<TextFormField>(
      find.byKey(const ValueKey('model-groq')),
    );
    expect(model.controller!.text, 'llama-3.1-8b-instant');
    await tester.enterText(
      find.byKey(const ValueKey('api-key-field')),
      'test-only-key',
    );
    await tester.pump();
    final saveKey = find.byKey(const ValueKey('save-api-key'));
    await tester.ensureVisible(saveKey);
    await tester.pump();
    await tester.tap(saveKey);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(credentials.values[CloudProvider.groq], 'test-only-key');
    expect(credentials.values[CloudProvider.openAi], isNull);
    expect(
      settings.settings.toJson().toString(),
      isNot(contains('test-only-key')),
    );

    final preset = find.byKey(const ValueKey('local-light-preset'));
    await tester.ensureVisible(preset);
    await tester.pump();
    await tester.tap(preset);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final localModel = tester.widget<TextFormField>(
      find.descendant(
        of: find.byKey(const ValueKey('local-model-field')),
        matching: find.byType(TextFormField),
      ),
    );
    expect(localModel.controller!.text, LocalModelProfile.recommendedModel);
    final save = find.text('Enregistrer la configuration');
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(settings.settings.provider, CloudProvider.groq);
    expect(settings.settings.groqModel, 'llama-3.1-8b-instant');
    expect(settings.settings.localLowMemoryMode, isTrue);
    expect(settings.settings.contextMessages, 8);
    expect(tester.takeException(), isNull);
  });
}
