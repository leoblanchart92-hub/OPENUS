import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ai/core/models/chat_message.dart';
import 'package:nexus_ai/core/models/conversation.dart';
import 'package:nexus_ai/services/update_checkpoint.dart';
import 'package:nexus_ai/services/update_service.dart';
import 'package:nexus_ai/settings/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('canonical bundled version is 0.1.1', () async {
    expect(await UpdateService.currentVersion(), '0.1.1');
  });

  test('stable semantic versions compare numerically', () {
    expect(UpdateService.isNewer('0.1.10', '0.1.9'), isTrue);
    expect(UpdateService.isNewer('1.0.0', '0.99.99'), isTrue);
    expect(UpdateService.isNewer('0.1.1', '0.1.1'), isFalse);
    expect(UpdateService.isNewer('0.1.0', '0.1.1'), isFalse);
    for (final bad in ['0.1.2-beta', '01.2.3', '1.2', 'v1.2.3']) {
      expect(() => UpdateService.isNewer(bad, '0.1.1'), throwsFormatException);
    }
  });

  test('only exact official repository installer paths are accepted', () {
    const path = '/leoblanchart92-hub/OPENUS/releases/download/v0.1.2/Nexus-AI-Setup.exe';
    expect(UpdateService.officialAsset(Uri.parse('https://github.com$path'), '0.1.2'), isTrue);
    for (final url in [
      'http://github.com$path', 'https://evil.example$path',
      'https://github.com.evil.example$path', 'https://user@github.com$path',
      'https://github.com$path?redirect=evil', 'https://github.com$path#fragment',
      'https://github.com:444$path',
      'https://github.com/other/OPENUS/releases/download/v0.1.2/Nexus-AI-Setup.exe',
    ]) {
      expect(UpdateService.officialAsset(Uri.parse(url), '0.1.2'), isFalse,
          reason: url);
    }
  });

  test('SHA-256 rejects truncation and tampering', () async {
    final dir = await Directory.systemTemp.createTemp('nexus-hash-test-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/installer.exe');
    await file.writeAsString('abc', flush: true);
    const digest = 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
    await UpdateService.verifyInstaller(file, 3, digest);
    await expectLater(UpdateService.verifyInstaller(file, 4, digest),
        throwsFormatException);
    await file.writeAsString('abd', flush: true);
    await expectLater(UpdateService.verifyInstaller(file, 3, digest),
        throwsFormatException);
  });

  test('upgrade checkpoint round-trips settings and conversations; backup survives', () async {
    final dir = await Directory.systemTemp.createTemp('nexus-checkpoint-test-');
    addTearDown(() async {
      UpdateCheckpoint.restored = null;
      await dir.delete(recursive: true);
    });
    final storage = File('${dir.path}/state.json');
    final date = DateTime.utc(2026, 1, 2);
    final state = UpdateCheckpoint(const AppSettings(reducedMotion: true), [
      Conversation(id: 'demo-conv-501', title: 'Conserver', updatedAt: date,
        messages: [ChatMessage(id: 'usr-502', sender: MessageSender.user,
          content: 'Bonjour Nyx', timestamp: date)]),
    ]);
    await state.save(storage: storage);
    await UpdateCheckpoint.load(storage: storage);
    expect(UpdateCheckpoint.restored!.settings.reducedMotion, isTrue);
    expect(UpdateCheckpoint.restored!.conversations.single.messages.single.content,
        'Bonjour Nyx');
    await state.save(storage: storage);
    expect(await File('${storage.path}.previous').exists(), isTrue);
    await storage.delete(); // Simulate interruption between rename operations.
    await UpdateCheckpoint.load(storage: storage);
    expect(UpdateCheckpoint.restored!.conversations.single.id, 'demo-conv-501');
  });
}
