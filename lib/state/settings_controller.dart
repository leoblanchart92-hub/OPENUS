import 'package:flutter/foundation.dart';
import '../data/credential_store.dart';
import '../data/settings_repository.dart';
import '../domain/ai.dart';
import '../domain/app_settings.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required SettingsRepository repository,
    required CredentialStore credentials,
    required AppSettings initial,
    String? warning,
  }) : _repository = repository,
       _credentials = credentials,
       _settings = initial,
       _notice = warning;
  final SettingsRepository _repository;
  final CredentialStore _credentials;
  AppSettings _settings;
  String? _notice;
  bool _busy = false;
  bool _disposed = false;
  final Set<CloudProvider> _configured = {};

  AppSettings get settings => _settings;
  String? get notice => _notice;
  bool get busy => _busy;
  bool hasKey(CloudProvider provider) => _configured.contains(provider);
  void clearNotice() {
    _notice = null;
    _notify();
  }

  Future<void> initialize() async {
    for (final provider in CloudProvider.values) {
      try {
        if (await _credentials.read(provider) != null) {
          _configured.add(provider);
        }
      } on CredentialFailure catch (error) {
        _notice = error.toString();
      }
    }
    _notify();
  }

  Future<bool> update(AppSettings next) => _mutate(() async {
    await _repository.save(next);
    _settings = next;
  });

  Future<bool> saveKey(CloudProvider provider, String key) => _mutate(() async {
    await _credentials.save(provider, key);
    _configured.add(provider);
  });

  Future<bool> deleteKey(CloudProvider provider) => _mutate(() async {
    await _credentials.delete(provider);
    _configured.remove(provider);
  });

  Future<bool> _mutate(Future<void> Function() action) async {
    if (_busy || _disposed) return false;
    _busy = true;
    _notice = null;
    _notify();
    var success = false;
    try {
      await action();
      success = true;
    } catch (_) {
      _notice =
          'Enregistrement impossible. Vérifiez le stockage de l’appareil ; la configuration précédente est conservée.';
    } finally {
      _busy = false;
      _notify();
    }
    return success;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
