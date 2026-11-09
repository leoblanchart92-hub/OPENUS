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

  test('redirects are restricted to the official signed release CDN', () {
    expect(UpdateService.trustedReleaseRedirect(Uri.parse(
      'https://release-assets.githubusercontent.com/github-production-release-asset/file?sig=token')),
      isTrue);
    for (final uri in [
      'http://release-assets.githubusercontent.com/file',
      'https://release-assets.githubusercontent.com.evil.example/file',
      'https://evil.example/file',
      'https://user@release-assets.githubusercontent.com/file',
      'https://release-assets.githubusercontent.com:444/file',
      'https://release-assets.githubusercontent.com/file#fragment',
      'file:///tmp/installer.exe',
    ]) {
      expect(UpdateService.trustedReleaseRedirect(Uri.parse(uri)), isFalse,
        reason: uri);
    }
  });

  Map<String, dynamic> release({String? digest, int size = 200000,
      String url = 'https://github.com/leoblanchart92-hub/OPENUS/releases/download/v0.1.2/Nexus-AI-Setup.exe'}) => {
    'draft': false, 'prerelease': false, 'tag_name': 'v0.1.2', 'body': 'Nouveautés',
    'assets': [<String, dynamic>{'name': 'Nexus-AI-Setup.exe',
      'browser_download_url': url, 'size': size,
      'digest': digest ?? 'sha256:${List.filled(64, 'a').join()}' }],
  };

  test('release metadata fails closed on missing, duplicate or invalid assets', () {
    final valid = UpdateService.parseRelease(release(), '0.1.1')!;
    expect(valid.version, '0.1.2');
    expect(valid.notes, 'Nouveautés');
    expect(valid.size, 200000);
    expect(UpdateService.parseRelease(release(), '0.1.2'), isNull);
    expect(UpdateService.parseRelease(release()..['draft'] = true, '0.1.1'), isNull);
    expect(UpdateService.parseRelease(release()..['prerelease'] = true, '0.1.1'), isNull);
    for (final bad in [release(digest: ''), release(digest: 'sha256:abc'),
        release(size: 0), release(size: -1),
        release(url: 'https://evil.example/Nexus-AI-Setup.exe')]) {
      expect(() => UpdateService.parseRelease(bad, '0.1.1'), throwsFormatException);
    }
    final missing = release()..['assets'] = <dynamic>[];
    expect(() => UpdateService.parseRelease(missing, '0.1.1'), throwsStateError);
    final duplicate = release();
    final assets = duplicate['assets'] as List<dynamic>;
    assets.add(assets.single);
    expect(() => UpdateService.parseRelease(duplicate, '0.1.1'), throwsStateError);
    final absentDigest = release();
    ((absentDigest['assets'] as List<dynamic>).single as Map<String, dynamic>)
        .remove('digest');
    expect(() => UpdateService.parseRelease(absentDigest, '0.1.1'), throwsFormatException);
  });

  test('corrupt primary is not silently overwritten, even with a valid backup', () async {
    final dir = await Directory.systemTemp.createTemp('nexus-corrupt-test-');
    addTearDown(() async {
      UpdateCheckpoint.restored = null;
      await dir.delete(recursive: true);
    });
    final storage = File('${dir.path}/state.json');
    const state = UpdateCheckpoint(AppSettings(), []);
    await state.save(storage: storage);
    await state.save(storage: storage);
    final previous = await File('${storage.path}.previous').readAsString();
    await storage.writeAsString('{incomplete', flush: true);
    UpdateCheckpoint.restored = null;
    await expectLater(UpdateCheckpoint.load(storage: storage), throwsFormatException);
    expect(UpdateCheckpoint.restored, isNull);
    expect(await storage.readAsString(), '{incomplete');
    expect(await File('${storage.path}.previous').readAsString(), previous);
  });

  test('unknown checkpoint schema and unwritable storage fail visibly', () async {
    final dir = await Directory.systemTemp.createTemp('nexus-schema-test-');
    addTearDown(() async {
      UpdateCheckpoint.restored = null;
      await dir.delete(recursive: true);
    });
    final storage = File('${dir.path}/state.json');
    await storage.writeAsString('{"schema":99}');
    await expectLater(UpdateCheckpoint.load(storage: storage), throwsFormatException);
    expect(await storage.readAsString(), '{"schema":99}');
    // The parent is deliberately a file: this fails on Linux and Windows,
    // independently of the hosted runner's administrative privileges.
    await expectLater(const UpdateCheckpoint(AppSettings(), [])
      .save(storage: File('${storage.path}/child.json')), throwsA(isA<FileSystemException>()));
    expect(await storage.readAsString(), '{"schema":99}');
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
