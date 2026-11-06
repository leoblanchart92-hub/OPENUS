import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/app_settings.dart';
import 'conversation_repository.dart';

class SettingsLoadResult {
  const SettingsLoadResult(this.settings, this.warning);
  final AppSettings settings;
  final String? warning;
}

class SettingsRepository {
  const SettingsRepository(this._preferences);
  static const _key = 'openus.settings.v1';
  final SharedPreferences _preferences;

  SettingsLoadResult load() {
    final raw = _preferences.getString(_key);
    if (raw == null) return const SettingsLoadResult(AppSettings(), null);
    try {
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Settings envelope');
      }
      return SettingsLoadResult(AppSettings.fromJson(value), null);
    } on FormatException {
      return const SettingsLoadResult(
        AppSettings(),
        'Paramètres endommagés : valeurs par défaut chargées. Aucun moteur n’a été activé automatiquement.',
      );
    }
  }

  Future<void> save(AppSettings settings) async {
    // SharedPreferences is for preferences ONLY, never API credentials.
    final saved = await _preferences.setString(
      _key,
      jsonEncode(settings.toJson()),
    );
    if (!saved) {
      throw const StorageFailure(
        'Les paramètres n’ont pas pu être enregistrés.',
      );
    }
  }
}
