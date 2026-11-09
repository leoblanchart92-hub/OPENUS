import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ai/services/desktop_window_service.dart';
import 'package:nexus_ai/widgets/desktop_window_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nexus_ai/desktop_window');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('safe error is visible and Retry performs recovery', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    var attempts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCapabilities') {
        return <String, Object>{
          'supported': true,
          'compactMode': true,
          'isCompact': false,
        };
      }
      attempts++;
      if (attempts == 1) {
        throw PlatformException(code: 'sensitive_code',
            message: 'SECRET password path', details: 'SECRET');
      }
      return true;
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    await tester.pumpWidget(MaterialApp(
      home: DesktopWindowFeedback(
        service: service,
        child: const Scaffold(body: Text('Contenu existant')),
      ),
    ));
    await service.setCompactView(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Impossible de changer'), findsOneWidget);
    expect(find.textContaining('SECRET'), findsNothing);
    expect(find.textContaining('sensitive_code'), findsNothing);
    expect(find.text('Contenu existant'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(attempts, 2);
    expect(service.isCompactView, isTrue);
    expect(find.textContaining('Impossible de changer'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('startup error predating listener is shown once', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw MissingPluginException();
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    await service.initialize();
    await tester.pumpWidget(MaterialApp(
      home: DesktopWindowFeedback(
        service: service,
        child: const Scaffold(body: Text('Application')),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('commandes de fenêtre sont indisponibles'),
        findsOneWidget);
    await service.setCompactView(true); // Non-error notification.
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await service.setCompactView(false);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
