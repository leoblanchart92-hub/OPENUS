import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ai/ai/demo_ai_service.dart';
import 'package:nexus_ai/app.dart';

void main() {
  testWidgets('Desktop viewport renders sidebar and all destinations',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      NexusAiApp(
        aiProvider: DemoAiService(simulatedDelay: Duration.zero),
        speakingShowcaseDuration: Duration.zero,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Nexus AI'), findsOneWidget);
    expect(find.text('Conversations'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('Compagnon'), findsOneWidget);
    expect(find.text('Paramètres'), findsOneWidget);

    // Switch to Companion Studio
    await tester.tap(find.text('Compagnon'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Studio Compagnon Nyx'), findsOneWidget);

    // Switch to History and test search bar
    await tester.tap(find.text('Historique'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Historique des discussions'), findsOneWidget);

    // Switch to Settings and verify Groq Phase 2 honest status
    await tester.tap(find.text('Paramètres'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Groq uniquement • Inactif'), findsOneWidget);

    // Switch to Conversations and send a demo message
    await tester.tap(find.text('Conversations'));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField).last, 'Salut Nyx !');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('chat_send_button')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Salut Nyx !'), findsOneWidget);
    expect(find.textContaining('[Réponse de démonstration]'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Mobile viewport uses bottom navigation and compact preview',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      NexusAiApp(
        aiProvider: DemoAiService(simulatedDelay: Duration.zero),
        speakingShowcaseDuration: Duration.zero,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Mobile bottom labels
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Nyx'), findsOneWidget);
    expect(find.text('Réglages'), findsOneWidget);

    for (final label in ['Nyx', 'Réglages', 'Historique', 'Accueil']) {
      await tester.tap(find.text(label).last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }

    // Toggle compact companion view from AppBar icon
    await tester.tap(
      find.byKey(const ValueKey<String>('mobile_compact_button')),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Nyx Compact'), findsOneWidget);

    // Expand back to full view
    await tester.tap(find.byIcon(Icons.open_in_full_rounded));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Chat'), findsOneWidget);

    // Open Conversations and verify virtual keyboard keeps composer visible
    await tester.tap(find.text('Chat'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey<String>('chat_send_button')), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey<String>('chat_send_button')), findsOneWidget);
    expect(find.text('Réglages'), findsNothing);
    tester.view.resetViewInsets();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
