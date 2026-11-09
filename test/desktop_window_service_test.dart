import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ai/services/desktop_window_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('nexus_ai/desktop_window');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Map<String, Object> capabilities() => <String, Object>{
        'supported': true,
        'compactMode': true,
        'alwaysOnTop': true,
        'minimize': true,
        'dragWindow': true,
        'isCompact': false,
        'isAlwaysOnTop': false,
      };

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    test('$platform never invokes the Windows channel', () async {
      debugDefaultTargetPlatformOverride = platform;
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (_) async {
        calls++;
        return null;
      });
      final service = DesktopWindowService();
      addTearDown(service.dispose);
      await service.initialize();
      await service.setCompactView(true);
      expect(service.isCompactView, isTrue);
      expect(service.isNativeWindowsSupported, isFalse);
      expect(await service.setAlwaysOnTop(true), isFalse);
      expect(await service.minimizeWindow(), isFalse);
      expect(await service.restoreWindow(), isFalse);
      await service.startWindowDrag();
      expect(calls, 0);
    });
  }

  test('compact mode waits for native acknowledgement and ignores double tap',
      () async {
    final pending = Completer<bool>();
    var compactCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCapabilities') {
        return capabilities();
      }
      expect(call.method, 'setCompactMode');
      expect(call.arguments, {'compact': true, 'width': 310, 'height': 390});
      compactCalls++;
      return pending.future;
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    await service.initialize();
    final transition = service.setCompactView(true);
    final duplicate = service.setCompactView(true);
    expect(service.isCompactView, isFalse);
    pending.complete(true);
    await transition;
    expect(service.isCompactView, isTrue);
    await duplicate;
    expect(compactCalls, 1);
  });

  test('native failure preserves compact and topmost state', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCapabilities') {
        return capabilities();
      }
      throw PlatformException(code: 'window_operation_failed', message: 'test');
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    await service.initialize();
    await service.setCompactView(true);
    expect(service.isCompactView, isFalse);
    expect(service.lastStatusMessage, contains('Impossible'));
    expect(service.lastStatusMessage, isNot(contains('test')));
    expect(await service.setAlwaysOnTop(true), isFalse);
    expect(service.isAlwaysOnTop, isFalse);
  });

  test('native false acknowledgement is not reported as applied', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return call.method == 'getCapabilities' ? capabilities() : false;
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    await service.initialize();
    await service.setCompactView(true);
    expect(service.isCompactView, isFalse);
    expect(await service.setAlwaysOnTop(true), isFalse);
  });

  test('late compact acknowledgement after disposal cannot notify', () async {
    final pending = Completer<bool>();
    final started = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCapabilities') {
        return capabilities();
      }
      started.complete();
      return pending.future;
    });
    final service = DesktopWindowService();
    await service.initialize();
    final transition = service.setCompactView(true);
    await started.future;
    service.dispose();
    pending.complete(true);
    await transition;
    expect(service.isCompactView, isFalse);
  });

  test('initialization is shared and early opposing requests stay ordered', () async {
    final probe = Completer<Map<String, Object>>();
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'getCapabilities') {
        return probe.future;
      }
      return (call.arguments as Map)['compact'] as bool;
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    final firstProbe = service.initialize();
    final secondProbe = service.initialize();
    expect(identical(firstProbe, secondProbe), isTrue);
    final enter = service.setCompactView(true);
    final leave = service.setCompactView(false);
    probe.complete(capabilities());
    await Future.wait([firstProbe, secondProbe, enter, leave]);
    expect(calls, ['getCapabilities', 'setCompactMode', 'setCompactMode']);
    expect(service.isCompactView, isFalse);
  });

  test('compact and topmost actions cannot overlap on the channel', () async {
    final compactReply = Completer<bool>();
    final calls = <String>[];
    final compactStarted = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'getCapabilities') {
        return capabilities();
      }
      if (call.method == 'setCompactMode') {
        compactStarted.complete();
        return compactReply.future;
      }
      return true;
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    final compact = service.setCompactView(true);
    final topmost = service.setAlwaysOnTop(true);
    await compactStarted.future;
    expect(calls, ['getCapabilities', 'setCompactMode']);
    compactReply.complete(true);
    await compact;
    expect(await topmost, isTrue);
    expect(calls.last, 'setAlwaysOnTop');
  });

  test('disposal during initialization prevents queued native mutations', () async {
    final probe = Completer<Map<String, Object>>();
    var mutationCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCapabilities') {
        return probe.future;
      }
      mutationCalls++;
      return true;
    });
    final service = DesktopWindowService();
    final startup = service.initialize();
    final compact = service.setCompactView(true);
    final topmost = service.setAlwaysOnTop(true);
    service.dispose();
    probe.complete(capabilities());
    await Future.wait([startup, compact]);
    expect(await topmost, isFalse);
    expect(mutationCalls, 0);
    expect(service.isCompactView, isFalse);
  });

  test('native details are hidden and retry recovers after failure', () async {
    var fail = true;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCapabilities') {
        return capabilities();
      }
      if (fail) {
        throw PlatformException(code: 'private', message: 'SECRET path token',
            details: {'password': 'SECRET'});
      }
      return (call.arguments as Map)['compact'] as bool;
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    await service.setCompactView(true);
    expect(service.lastStatusMessage, isNot(contains('SECRET')));
    expect(service.canRetry, isTrue);
    final sequence = service.errorSequence;
    fail = false;
    await service.retryLastOperation();
    expect(service.isCompactView, isTrue);
    expect(service.lastStatusMessage, isNull);
    expect(service.errorSequence, sequence);
  });

  test('missing plugin keeps preview and retry probes again', () async {
    var available = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (!available) {
        throw MissingPluginException();
      }
      return capabilities();
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    await service.setCompactView(true);
    expect(service.isCompactView, isTrue);
    expect(service.isNativeWindowsSupported, isFalse);
    available = true;
    await service.retryLastOperation();
    expect(service.isNativeWindowsSupported, isTrue);
    expect(service.isCompactView, isFalse);
  });

  test('null reply reports error, then queued request can succeed', () async {
    var fail = true;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCapabilities') {
        return capabilities();
      }
      return fail ? null : (call.arguments as Map)['alwaysOnTop'];
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    expect(await service.setAlwaysOnTop(true), isFalse);
    expect(service.lastStatusMessage, isNotNull);
    fail = false;
    expect(await service.setAlwaysOnTop(true), isTrue);
    expect(await service.setAlwaysOnTop(false), isTrue);
    expect(service.isAlwaysOnTop, isFalse);
  });


  test('queued toggles use latest acknowledged state', () async {
    final requested = <bool>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCapabilities') {
        return capabilities();
      }
      final compact = (call.arguments as Map)['compact'] as bool;
      requested.add(compact);
      return compact;
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    await Future.wait([service.toggleCompactView(), service.toggleCompactView()]);
    expect(requested, [true, false]);
    expect(service.isCompactView, isFalse);
  });

  test('failure does not poison the action queue', () async {
    var attempts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getCapabilities') {
        return capabilities();
      }
      attempts++;
      if (attempts == 1) {
        throw PlatformException(code: 'failed');
      }
      return true;
    });
    final service = DesktopWindowService();
    addTearDown(service.dispose);
    final compact = service.setCompactView(true);
    final topmost = service.setAlwaysOnTop(true);
    await compact;
    expect(await topmost, isTrue);
    expect(service.isCompactView, isFalse);
    expect(service.isAlwaysOnTop, isTrue);
  });

}
