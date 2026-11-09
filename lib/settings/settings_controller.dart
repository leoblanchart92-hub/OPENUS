import 'package:flutter/foundation.dart';

import '../companion/companion_controller.dart';
import '../companion/companion_state.dart';
import 'app_settings.dart';

/// Manages application preferences and keeps [CompanionController] synced.
class SettingsController extends ChangeNotifier {
  SettingsController({
    required CompanionController companionController,
    AppSettings initialSettings = const AppSettings(),
  })  : _companionController = companionController,
        _settings = initialSettings {
    _syncCompanion();
  }

  final CompanionController _companionController;
  AppSettings _settings;

  AppSettings get settings => _settings;

  void setShowInAppFloatingCompanion(bool enabled) {
    if (_settings.showInAppFloatingCompanion == enabled) {
      return;
    }
    _settings = _settings.copyWith(showInAppFloatingCompanion: enabled);
    notifyListeners();
  }

  void setShowOrbitalAura(bool enabled) {
    if (_settings.showOrbitalAura == enabled) {
      return;
    }
    _settings = _settings.copyWith(showOrbitalAura: enabled);
    _syncCompanion();
    notifyListeners();
  }

  void setGlowIntensity(double value) {
    final clamped = value.clamp(0.2, 1.0);
    if ((_settings.glowIntensity - clamped).abs() < 0.001) {
      return;
    }
    _settings = _settings.copyWith(glowIntensity: clamped);
    _syncCompanion();
    notifyListeners();
  }

  void setReducedMotion(bool enabled) {
    if (_settings.reducedMotion == enabled) {
      return;
    }
    _settings = _settings.copyWith(reducedMotion: enabled);
    _syncCompanion();
    notifyListeners();
  }

  void setPalette(CompanionPaletteId paletteId) {
    if (_settings.paletteId == paletteId) {
      return;
    }
    _settings = _settings.copyWith(paletteId: paletteId);
    _syncCompanion();
    notifyListeners();
  }

  void setPreferredGroqModel(String modelId) {
    if (_settings.preferredGroqModelId == modelId) {
      return;
    }
    _settings = _settings.copyWith(preferredGroqModelId: modelId);
    notifyListeners();
  }

  void resetDefaults() {
    _settings = const AppSettings();
    _syncCompanion();
    notifyListeners();
  }

  void _syncCompanion() {
    _companionController.setPalette(_settings.paletteId);
    _companionController.setGlowIntensity(_settings.glowIntensity);
    _companionController.setShowOrbitalAura(_settings.showOrbitalAura);
    _companionController.setReducedMotion(_settings.reducedMotion);
  }
}
