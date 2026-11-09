import 'dart:convert';
import 'dart:io';

/// Checks GitHub Releases and installs the official Windows setup package.
class UpdateService {
  UpdateService._();
  static const currentVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');
  static const _releaseApi = 'https://api.github.com/repos/leoblanchart92-hub/OPENUS/releases/latest';

  static Future<UpdateInfo?> checkForUpdate() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(_releaseApi));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.userAgentHeader, 'Nexus-AI-Updater');
      final response = await request.close().timeout(const Duration(seconds: 20));
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode == HttpStatus.notFound) {
        throw StateError('Aucune version officielle n’a encore été publiée.');
      }
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('GitHub a répondu avec le code ${response.statusCode}.');
      }
      final release = jsonDecode(body) as Map<String, dynamic>;
      final tag = release['tag_name'] as String? ?? '';
      final latest = tag.startsWith('v') ? tag.substring(1) : tag;
      if (latest.isEmpty || !_isNewer(latest, currentVersion)) return null;
      final assets = release['assets'] as List<dynamic>? ?? const [];
      String? url;
      for (final item in assets) {
        final asset = item as Map<String, dynamic>;
        if (asset['name'] == 'Nexus-AI-Setup.exe') {
          url = asset['browser_download_url'] as String?;
          break;
        }
      }
      if (url == null || !url.startsWith('https://')) {
        throw StateError('La nouvelle version existe, mais son installateur Windows est absent.');
      }
      return UpdateInfo(version: latest, installerUrl: url);
    } finally {
      client.close(force: true);
    }
  }

  static bool _isNewer(String latest, String current) {
    List<int> parts(String value) => value.split('+').first.split('-').first
        .split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final a = parts(latest), b = parts(current);
    for (var i = 0; i < 3; i++) {
      final left = i < a.length ? a[i] : 0;
      final right = i < b.length ? b[i] : 0;
      if (left != right) return left > right;
    }
    return false;
  }

  static Future<void> installUpdate(UpdateInfo info) async {
    if (!Platform.isWindows) throw UnsupportedError('Installation automatique disponible sur Windows uniquement.');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    final directory = await Directory.systemTemp.createTemp('nexus-ai-update-');
    final installer = File('${directory.path}\\Nexus-AI-Setup.exe');
    try {
      final request = await client.getUrl(Uri.parse(info.installerUrl));
      request.headers.set(HttpHeaders.userAgentHeader, 'Nexus-AI-Updater');
      final response = await request.close().timeout(const Duration(minutes: 5));
      if (response.statusCode != HttpStatus.ok) throw HttpException('Téléchargement impossible (HTTP ${response.statusCode}).');
      final sink = installer.openWrite();
      await response.pipe(sink);
      if (!await installer.exists() || await installer.length() < 102400) {
        throw StateError('Le fichier d’installation téléchargé est incomplet.');
      }
      await Process.start(installer.path, const ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-'], mode: ProcessStartMode.detached);
      exit(0);
    } finally {
      client.close(force: true);
    }
  }
}

class UpdateInfo {
  const UpdateInfo({required this.version, required this.installerUrl});
  final String version;
  final String installerUrl;
}