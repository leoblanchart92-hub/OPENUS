import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'companion_state.dart';

/// Coordinates Nyx's state machine, facial expressions, gaze tracking,
/// and reaction lifecycle across all screens and compact views.
class CompanionController extends ChangeNotifier {
  CompanionState _state = CompanionState.idle;
  CompanionMood _mood = CompanionMood.neutral;
  CompanionPaletteId _paletteId = CompanionPaletteId.neonViolet;
  Offset _gazeOffset = Offset.zero;
  double _glowIntensity = 0.82;
  bool _showOrbitalAura = true;
  bool _reducedMotion = false;
  int _reactionPulse = 0;
  int _interactionCount = 0;

  Timer? _reactionTimer;
  Timer? _settleTimer;
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  CompanionState get state => _state;
  CompanionMood get mood => _mood;
  CompanionPaletteId get paletteId => _paletteId;
  Offset get gazeOffset => _gazeOffset;
  double get glowIntensity => _glowIntensity;
  bool get showOrbitalAura => _showOrbitalAura;
  bool get reducedMotion => _reducedMotion;
  int get reactionPulse => _reactionPulse;
  int get interactionCount => _interactionCount;

  void setState(CompanionState nextState) {
    if (_disposed) {
      return;
    }
    _cancelTimers();
    if (_state == nextState) {
      return;
    }
    _state = nextState;
    if (nextState == CompanionState.reacting) {
      _reactionPulse++;
    }
    _safeNotify();
  }

  void setMood(CompanionMood nextMood) {
    if (_disposed || _mood == nextMood) {
      return;
    }
    _mood = nextMood;
    _safeNotify();
  }

  void setPalette(CompanionPaletteId nextPalette) {
    if (_disposed || _paletteId == nextPalette) {
      return;
    }
    _paletteId = nextPalette;
    _safeNotify();
  }

  void setGlowIntensity(double value) {
    final clamped = value.clamp(0.2, 1.0);
    if (_disposed || (_glowIntensity - clamped).abs() < 0.001) {
      return;
    }
    _glowIntensity = clamped;
    _safeNotify();
  }

  void setShowOrbitalAura(bool enabled) {
    if (_disposed || _showOrbitalAura == enabled) {
      return;
    }
    _showOrbitalAura = enabled;
    _safeNotify();
  }

  void setReducedMotion(bool enabled) {
    if (_disposed || _reducedMotion == enabled) {
      return;
    }
    _reducedMotion = enabled;
    _safeNotify();
  }

  void updateGaze(Offset normalizedOffset) {
    final clamped = Offset(
      normalizedOffset.dx.clamp(-1.0, 1.0),
      normalizedOffset.dy.clamp(-1.0, 1.0),
    );
    if (_disposed || (_gazeOffset - clamped).distance < 0.01) {
      return;
    }
    _gazeOffset = clamped;
    _safeNotify();
  }

  void resetGaze() {
    if (_disposed || _gazeOffset == Offset.zero) {
      return;
    }
    _gazeOffset = Offset.zero;
    _safeNotify();
  }

  /// Triggered immediately when the user sends a message:
  /// plays a brief energetic reaction, then shifts into thinking mode.
  void triggerMessageSentReaction() {
    if (_disposed) {
      return;
    }
    _cancelTimers();
    _state = CompanionState.reacting;
    _mood = CompanionMood.happy;
    _reactionPulse++;
    _interactionCount++;
    _safeNotify();

    _reactionTimer = Timer(const Duration(milliseconds: 520), () {
      if (_disposed) {
        return;
      }
      _state = CompanionState.thinking;
      _mood = CompanionMood.focused;
      _safeNotify();
    });
  }

  /// Triggered when the assistant begins outputting a response.
  void triggerResponseStarted() {
    if (_disposed) {
      return;
    }
    _cancelTimers();
    _state = CompanionState.speaking;
    _mood = CompanionMood.happy;
    _safeNotify();
  }

  /// Triggered after a response finishes: enters attentive waiting briefly,
  /// then gently settles into idle rest.
  void triggerResponseFinished() {
    if (_disposed) {
      return;
    }
    _cancelTimers();
    _state = CompanionState.waiting;
    _mood = CompanionMood.curious;
    _safeNotify();

    _settleTimer = Timer(const Duration(milliseconds: 2600), () {
      if (_disposed) {
        return;
      }
      _state = CompanionState.idle;
      _mood = CompanionMood.neutral;
      _safeNotify();
    });
  }

  /// Triggered when the user taps or pets Nyx directly.
  void tapCompanion() {
    if (_disposed) {
      return;
    }
    _cancelTimers();
    _interactionCount++;
    _reactionPulse++;
    _state = CompanionState.reacting;
    _mood = _interactionCount.isEven
        ? CompanionMood.playful
        : CompanionMood.happy;
    _safeNotify();

    _reactionTimer = Timer(const Duration(milliseconds: 950), () {
      if (_disposed) {
        return;
      }
      _state = CompanionState.waiting;
      _safeNotify();

      _settleTimer = Timer(const Duration(milliseconds: 1400), () {
        if (_disposed) {
          return;
        }
        _state = CompanionState.idle;
        _mood = CompanionMood.neutral;
        _safeNotify();
      });
    });
  }

  void _cancelTimers() {
    _reactionTimer?.cancel();
    _reactionTimer = null;
    _settleTimer?.cancel();
    _settleTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    super.dispose();
  }
}
