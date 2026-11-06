import 'package:flutter/foundation.dart';
import '../data/credential_store.dart';
import '../domain/ai.dart';
import '../domain/app_settings.dart';
import '../services/ai/engine_router.dart';

enum HealthState { unknown, checking, available, unavailable, notConfigured }
class EngineHealth {
  const EngineHealth({this.state = HealthState.unknown, this.message = 'Disponibilité non vérifiée.', this.models = const [], this.checkedAt});
  final HealthState state;
  final String message;
  final List<String> models;
  final DateTime? checkedAt;
}

class AvailabilityController extends ChangeNotifier {
  AvailabilityController(this._router, this._credentials);
  final EngineRouter _router;
  final CredentialStore _credentials;
  final Map<EngineKind, EngineHealth> _health = {};
  int _generation = 0;
  bool _busy = false;
  bool _disposed = false;
  bool get busy => _busy;
  EngineHealth operator [](EngineKind kind) => _health[kind] ?? const EngineHealth();

  void invalidate() {
    _generation++;
    _health.clear(); _busy = false; _notify();
  }
  void record(EngineKind kind, EngineProbe probe) {
    _health[kind] = EngineHealth(state: probe.available ? HealthState.available : HealthState.unavailable,
      message: probe.message, models: probe.models, checkedAt: DateTime.now());
    _notify();
  }
  void noteSuccess(EngineKind kind) {
    record(kind, EngineProbe(available: true, message: 'Une réponse réelle a été reçue.', models: this[kind].models));
  }

  Future<void> refresh(AppSettings settings, {EngineKind? only}) async {
    if (_busy) return;
    final generation = ++_generation;
    _busy = true;
    if (only == null) _health.clear();
    for (final kind in EngineKind.values.where((k) => only == null || k == only)) {
      _health[kind] = const EngineHealth(state: HealthState.checking, message: 'Vérification en cours…');
    }
    _notify();
    bool current() => !_disposed && generation == _generation;
    Future<void> check(EngineKind kind, Future<EngineProbe> Function() action) async {
      try {
        final probe = await action();
        if (current()) record(kind, probe);
      } on AiException catch (error) {
        if (current()) record(kind, EngineProbe(available: false, message: error.message));
      } catch (_) {
        if (current()) record(kind, const EngineProbe(available: false, message: 'Vérification impossible. Consultez les paramètres du moteur.'));
      }
    }
    final tasks = <Future<void>>[];
    if (only == null || only == EngineKind.local) {
      if (settings.endpointError == null) {
        tasks.add(check(EngineKind.local, () => _router.localEngine(settings.localEndpoint).probe()));
      } else {
        _health[EngineKind.local] = EngineHealth(state: HealthState.notConfigured, message: settings.endpointError!);
      }
    }
    for (final provider in CloudProvider.values) {
      final kind = provider == CloudProvider.openAi ? EngineKind.openAi : EngineKind.anthropic;
      if (only != null && only != kind) continue;
      final model = provider == CloudProvider.openAi ? settings.openAiModel : settings.anthropicModel;
      try {
        final key = await _credentials.read(provider);
        if (!current()) return;
        if (key == null || model.trim().isEmpty) {
          _health[kind] = const EngineHealth(state: HealthState.notConfigured, message: 'Modèle ou clé API non configuré.');
        } else {
          tasks.add(check(kind, () => _router.cloudEngine(provider).probe(apiKey: key)));
        }
      } catch (_) {
        _health[kind] = const EngineHealth(state: HealthState.unavailable, message: 'Stockage sécurisé indisponible.');
      }
    }
    await Future.wait(tasks);
    if (current()) { _busy = false; _notify(); }
  }
  void _notify() { if (!_disposed) notifyListeners(); }
  @override
  void dispose() { _disposed = true; _generation++; super.dispose(); }
}
