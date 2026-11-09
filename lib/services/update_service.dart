import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

/// Only stable releases and assets owned by the official repository are trusted.
class UpdateService {
  static const repository = 'leoblanchart92-hub/OPENUS';
  static bool _installing = false;
  static Future<void> Function()? beforeInstall;

  static Future<String> currentVersion() async {
    final manifest = await rootBundle.loadString('pubspec.yaml');
    return RegExp(r'^version: (\d+\.\d+\.\d+)\+\d+$', multiLine: true)
        .firstMatch(manifest)!
        .group(1)!;
  }

  static bool isNewer(String latest, String current) {
    List<int> parse(String value) {
      if (!RegExp(r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$')
          .hasMatch(value)) {
        throw const FormatException('Expected stable semantic version');
      }
      return value.split('.').map(int.parse).toList();
    }
    final a = parse(latest);
    final b = parse(current);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) {
        return a[i] > b[i];
      }
    }
    return false;
  }

  static bool officialAsset(Uri uri, String version) =>
      uri.scheme == 'https' && uri.host == 'github.com' &&
      !uri.hasPort && uri.userInfo.isEmpty && !uri.hasQuery &&
      !uri.hasFragment &&
      uri.path == '/$repository/releases/download/v$version/Nexus-AI-Setup.exe';

  static bool trustedReleaseRedirect(Uri uri) =>
      uri.scheme == 'https' && uri.userInfo.isEmpty &&
      !uri.hasPort && !uri.hasFragment &&
      uri.host == 'release-assets.githubusercontent.com';

  static Future<HttpClientResponse> _get(HttpClient client, Uri uri,
      {bool asset = false}) async {
    for (var redirects = 0; redirects < 4; redirects++) {
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 20));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.userAgentHeader, 'Nexus-AI-Updater');
      final response = await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 404) {
        return response;
      }
      if (asset && [301, 302, 303, 307, 308].contains(response.statusCode)) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null) {
          throw const HttpException('Missing redirect');
        }
        final next = uri.resolve(location);
        // GitHub's signed release storage redirect, not arbitrary HTTPS hosts.
        if (!trustedReleaseRedirect(next)) {
          throw const HttpException('Untrusted download redirect');
        }
        await response.drain<void>().timeout(const Duration(seconds: 30));
        uri = next;
      } else {
        throw HttpException('GitHub HTTP ${response.statusCode}');
      }
    }
    throw const HttpException('Too many redirects');
  }

  static Future<UpdateInfo?> checkForUpdate() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final response = await _get(client,
          Uri.https('api.github.com', '/repos/$repository/releases/latest'));
      if (response.statusCode == 404) {
        return null;
      }
      final body = await utf8.decoder.bind(response)
          .join().timeout(const Duration(seconds: 30));
      return parseRelease(jsonDecode(body) as Map<String, dynamic>,
          await currentVersion());
    } finally {
      client.close(force: true);
    }
  }

  static UpdateInfo? parseRelease(Map<String, dynamic> release, String current) {
    if (release['draft'] != false || release['prerelease'] != false) {
      return null;
    }
    final tag = release['tag_name'] as String;
    if (!tag.startsWith('v')) {
      throw const FormatException('Invalid release tag');
    }
    final version = tag.substring(1);
    if (!isNewer(version, current)) {
      return null;
    }
    final assets = release['assets'] as List<dynamic>;
    final asset = assets.cast<Map<String, dynamic>>().singleWhere(
        (item) => item['name'] == 'Nexus-AI-Setup.exe');
    final url = Uri.parse(asset['browser_download_url'] as String);
    final digest = asset['digest'] as String? ?? '';
    final size = asset['size'] as int;
    if (!officialAsset(url, version) || size < 102400 ||
        !RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(digest)) {
      throw const FormatException('Invalid or unverifiable official installer');
    }
    return UpdateInfo(version, url, size, digest.substring(7),
        release['body'] as String? ?? 'Aucune note fournie.');
  }

  static Future<void> verifyInstaller(File file, int size, String digest) async {
    if (await file.length() != size ||
        (await sha256.bind(file.openRead()).first).toString() != digest) {
      throw const FormatException('Installer size or SHA-256 mismatch');
    }
  }

  static Future<void> installUpdate(UpdateInfo info) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('Windows only');
    }
    if (_installing) {
      throw StateError('Installation already in progress');
    }
    if (!officialAsset(info.url, info.version)) {
      throw const FormatException('Untrusted installer');
    }
    _installing = true;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    Directory? directory;
    var launched = false;
    try {
      directory = await Directory.systemTemp.createTemp('nexus-ai-update-');
      final file = File('${directory.path}/Nexus-AI-Setup.exe');
      final response = await _get(client, info.url, asset: true);
      if (response.statusCode != 200) {
        throw const HttpException('Installer missing');
      }
      final sink = file.openWrite();
      var bytes = 0;
      try {
        await for (final chunk in response.timeout(const Duration(seconds: 30))) {
          bytes += chunk.length;
          if (bytes > info.size) {
            throw const FormatException('Oversized download');
          }
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      await verifyInstaller(file, info.size, info.sha256);
      final checkpoint = beforeInstall;
      if (checkpoint == null) {
        throw StateError('Checkpoint unavailable');
      }
      await checkpoint();
      await Process.start(file.path, const [
        '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-', '/RELAUNCH=1'
      ], mode: ProcessStartMode.detached);
      launched = true;
      // Ask the native host to close, rather than abruptly terminating Dart.
      await SystemNavigator.pop();
    } finally {
      client.close(force: true);
      if (!launched) {
        _installing = false;
        if (directory != null) {
          await directory.delete(recursive: true);
        }
      }
    }
  }
}

class UpdateInfo {
  const UpdateInfo(this.version, this.url, this.size, this.sha256, this.notes);
  final String version;
  final Uri url;
  final int size;
  final String sha256;
  final String notes;
}
