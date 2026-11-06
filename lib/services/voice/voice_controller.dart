import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../domain/app_settings.dart';

/// Native platform voice, explicitly activated by the user. No wake-word,
/// background recording or always-on microphone is implemented in phase 1.
class VoiceController extends ChangeNotifier {
  VoiceController({stt.SpeechToText? recognition, FlutterTts? synthesis})
    : _recognition = recognition ?? stt.SpeechToText(),
      _synthesis = synthesis ?? FlutterTts() {
    _synthesis.setCompletionHandler(_speechFinished);
    _synthesis.setErrorHandler(_speechError);
  }
  final stt.SpeechToText _recognition;
  final FlutterTts _synthesis;
  bool _disposed = false;
  bool _listening = false;
  bool _speaking = false;
  bool _busy = false;
  bool _available = false;
  String? _error;
  String _prefix = '';
  void Function(String)? _onTranscript;
  AppSettings _settings = const AppSettings();

  bool get listening => _listening;
  bool get speaking => _speaking;
  bool get busy => _busy;
  bool get available => _available;
  String? get error => _error;
  bool get supported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.windows;

  void configure(AppSettings settings) {
    _settings = settings;
  }

  void clearError() {
    _error = null;
    _notify();
  }

  Future<bool> initializeMicrophone() async {
    if (_busy || _disposed) return false;
    if (!supported) {
      _error =
          'La reconnaissance vocale native cible Android et Windows dans cette version.';
      _notify();
      return false;
    }
    _busy = true;
    _error = null;
    _notify();
    try {
      await stopSpeaking();
      _available = await _recognition.initialize(
        onError: (event) {
          _error =
              'Microphone : ${event.errorMsg}. Vérifiez les permissions et le service de reconnaissance.';
          _listening = false;
          _notify();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _listening = false;
            _notify();
          }
        },
      );
      if (!_available) {
        _error =
            'Aucun service de reconnaissance vocale disponible, ou permission refusée.';
      }
      return _available;
    } catch (_) {
      _available = false;
      _error =
          'Initialisation du microphone impossible. Vérifiez les permissions de l’appareil.';
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> toggleListening(
    String currentText,
    void Function(String) onTranscript,
  ) async {
    if (_listening) {
      await stopListening();
      return;
    }
    if (!_available && !await initializeMicrophone()) return;
    if (_disposed) return;
    await stopSpeaking();
    _prefix = currentText.trim();
    _onTranscript = onTranscript;
    _busy = true;
    _error = null;
    _notify();
    try {
      await _recognition.listen(
        onResult: (result) {
          if (_disposed) return;
          final text = result.recognizedWords.trim();
          final full = [
            _prefix,
            text,
          ].where((part) => part.isNotEmpty).join(' ');
          _onTranscript?.call(full);
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: _settings.voiceLocale,
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          onDevice: false,
        ),
      );
      _listening = true;
    } catch (_) {
      _error =
          'Écoute impossible. Le service vocal peut être absent ou occuper le microphone.';
      _listening = false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> stopListening() async {
    try {
      await _recognition.stop();
    } catch (_) {
      _error = 'Arrêt du microphone impossible.';
    }
    _listening = false;
    _notify();
  }

  Future<bool> speak(String text) async {
    if (text.trim().isEmpty || _disposed) return false;
    if (!supported) {
      _error = 'Synthèse vocale prévue pour Android et Windows.';
      _notify();
      return false;
    }
    try {
      if (_listening) await stopListening();
      await _synthesis.stop();
      await _synthesis.setLanguage(_settings.voiceLocale);
      await _synthesis.setSpeechRate(_settings.speechRate);
      _speaking = true;
      _error = null;
      _notify();
      final result = await _synthesis.speak(text);
      if (result == 0) throw StateError('TTS failure');
      return true;
    } catch (_) {
      _speaking = false;
      _error =
          'Synthèse indisponible. Installez ou activez une voix dans les réglages du système.';
      _notify();
      return false;
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _synthesis.stop();
    } catch (_) {
      /* Device may already be stopped. */
    }
    _speaking = false;
    _notify();
  }

  void _speechFinished() {
    _speaking = false;
    _notify();
  }

  void _speechError(dynamic _) {
    _speaking = false;
    _error = 'La synthèse vocale a rencontré une erreur système.';
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _onTranscript = null;
    // Best-effort native cleanup; callbacks are guarded against disposed state.
    _recognition.cancel().catchError((Object _) {});
    _synthesis.stop().catchError((Object _) {});
    super.dispose();
  }
}
