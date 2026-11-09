import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/responsive/responsive_layout.dart';

/// Describes the native desktop window controls exposed by the host runner.
class DesktopWindowCapabilities {
  const DesktopWindowCapabilities({
    required this.supported,
    required this.compactMode,
    required this.alwaysOnTop,
    required this.minimize,
    required this.dragWindow,
  });

  static const DesktopWindowCapabilities unsupported = DesktopWindowCapabilities(
    supported: false,
    compactMode: false,
    alwaysOnTop: false,
    minimize: false,
    dragWindow: false,
  );

  final bool supported;
  final bool compactMode;
  final bool alwaysOnTop;
  final bool minimize;
  final bool dragWindow;
}

/// Coordinates compact companion mode and native Windows 10/11 desktop window
/// actions through the `nexus_ai/desktop_window` MethodChannel.
///
/// On Android, iOS, or when the native channel is unavailable, native window
/// capabilities honestly report `false`, while in-app compact view remains usable.
class DesktopWindowService extends ChangeNotifier {
  DesktopWindowService({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'nexus_ai/desktop_window';

  final MethodChannel _channel;
  DesktopWindowCapabilities _capabilities =
      DesktopWindowCapabilities.unsupported;
  Future<void>? _initialization;
  Future<void> _operations = Future<void>.value();
  bool _disposed = false;
  bool _isCompactView = false;
  bool _isAlwaysOnTop = false;
  String? _lastStatusMessage;
  int _errorSequence = 0;
  Future<void> Function()? _retryAction;

  DesktopWindowCapabilities get capabilities => _capabilities;
  bool get isNativeWindowsSupported => _capabilities.supported;
  bool get isCompactView => _isCompactView;
  bool get isAlwaysOnTop => _isAlwaysOnTop;
  String? get lastStatusMessage => _lastStatusMessage;
  int get errorSequence => _errorSequence;
  bool get canRetry => _retryAction != null && !_disposed;

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _error(String message, [Future<void> Function()? retry]) {
    if (_disposed) {
      return;
    }
    _lastStatusMessage = message;
    _retryAction = retry;
    _errorSequence++;
    _safeNotify();
  }

  void _clearError() {
    _lastStatusMessage = null;
    _retryAction = null;
  }

  Future<void> retryLastOperation() async {
    if (_disposed) {
      return;
    }
    final retry = _retryAction;
    _retryAction = null;
    _lastStatusMessage = null;
    await retry?.call();
  }

  /// All callers share the same probe, including calls made before app startup
  /// completes. The native snapshot is applied before any queued mutation.
  Future<void> initialize() {
    if (_disposed) {
      return Future<void>.value();
    }
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    if (!ResponsiveLayout.isWindowsPlatform()) {
      return;
    }
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('getCapabilities');
      if (_disposed) {
        return;
      }
      if (result == null || result['supported'] != true) {
        _unavailable();
        return;
      }
      _capabilities = DesktopWindowCapabilities(
        supported: true,
        compactMode: result['compactMode'] == true,
        alwaysOnTop: result['alwaysOnTop'] == true,
        minimize: result['minimize'] == true,
        dragWindow: result['dragWindow'] == true,
      );
      _isCompactView = result['isCompact'] == true;
      _isAlwaysOnTop = result['isAlwaysOnTop'] == true;
      _clearError();
      _safeNotify();
    } on MissingPluginException {
      _unavailable();
    } on PlatformException {
      _unavailable();
    }
  }

  void _unavailable() {
    if (_disposed) {
      return;
    }
    _capabilities = DesktopWindowCapabilities.unsupported;
    _error(
      'Les commandes de fenêtre sont indisponibles. '
      'La vue compacte reste accessible dans l’application.',
      () => _enqueue<void>(() async {
        _initialization = null;
        await initialize();
      }, null),
    );
  }

  /// Serialize all native actions, not only compact mode. A failed action must
  /// not poison the queue; queued actions become no-ops after disposal.
  Future<T> _enqueue<T>(Future<T> Function() action, T cancelled) {
    final result = Completer<T>();
    _operations = _operations.then((_) async {
      if (_disposed) {
        result.complete(cancelled);
        return;
      }
      try {
        await initialize();
        result.complete(_disposed ? cancelled : await action());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<void> setCompactView(bool compact) =>
      _enqueue<void>(() => _changeCompact(compact), null);

  Future<void> _changeCompact(bool compact) async {
    if (_isCompactView == compact) {
      return;
    }
    if (!_capabilities.supported || !_capabilities.compactMode) {
      _isCompactView = compact;
      _safeNotify();
      return;
    }
    try {
      final applied = await _channel.invokeMethod<bool>(
        'setCompactMode',
        <String, dynamic>{'compact': compact, 'width': 310, 'height': 390},
      );
      if (_disposed) {
        return;
      }
      if (applied != null) {
        _isCompactView = applied;
      }
      if (applied != compact) {
        _compactError(compact);
      } else {
        _clearError();
        _safeNotify();
      }
    } on PlatformException {
      _compactError(compact);
    } on MissingPluginException {
      if (!_disposed) {
        _unavailable();
        _isCompactView = compact;
        _safeNotify();
      }
    }
  }

  void _compactError(bool compact) => _error(
        'Impossible de changer la taille de la fenêtre. Vous pouvez réessayer.',
        () => setCompactView(compact),
      );

  // Resolve toggles after earlier operations, not against a stale state.
  Future<void> toggleCompactView() => _enqueue<void>(
        () => _changeCompact(!_isCompactView), null);

  Future<bool> setAlwaysOnTop(bool alwaysOnTop) => _enqueue<bool>(() async {
        if (!_capabilities.supported || !_capabilities.alwaysOnTop) {
          if (ResponsiveLayout.isWindowsPlatform() &&
              !_capabilities.supported) {
            return false; // Preserve initialization error and its recovery.
          }
          _error('Le maintien au premier plan est disponible uniquement '
              'avec les commandes de fenêtre Windows.');
          return false;
        }
        try {
          final applied = await _channel.invokeMethod<bool>(
            'setAlwaysOnTop',
            <String, dynamic>{'alwaysOnTop': alwaysOnTop},
          );
          if (_disposed) {
            return false;
          }
          if (applied != null) {
            _isAlwaysOnTop = applied;
          }
          if (applied == alwaysOnTop) {
            _clearError();
            _safeNotify();
            return true;
          }
        } on MissingPluginException {
          _unavailable();
          return false;
        } on PlatformException {
          // Only the fixed, user-safe message below is published.
        }
        _error('Impossible de modifier le maintien au premier plan. '
            'Vous pouvez réessayer.', () async {
          await setAlwaysOnTop(alwaysOnTop);
        });
        return false;
      }, false);

  Future<bool> _windowAction(String method, String message, bool supported) async {
    if (!_capabilities.supported || !supported) {
      return false;
    }
    try {
      final applied = await _channel.invokeMethod<bool>(method);
      if (_disposed) {
        return false;
      }
      if (applied == true) {
        _clearError();
        _safeNotify();
        return true;
      }
    } on MissingPluginException {
      _unavailable();
      return false;
    } on PlatformException {
      // Never expose native exception messages, details or paths.
    }
    _error(message, method == 'startWindowDrag' ? null : () async {
      if (method == 'minimizeWindow') {
        await minimizeWindow();
      } else {
        await restoreWindow();
      }
    });
    return false;
  }

  Future<bool> minimizeWindow() => _enqueue<bool>(
        () => _windowAction('minimizeWindow',
            'Impossible de réduire la fenêtre. Réessayez ou utilisez la barre '
            'de titre Windows.', _capabilities.minimize), false);

  Future<bool> restoreWindow() => _enqueue<bool>(
        () => _windowAction('restoreWindow',
            'Impossible de restaurer la fenêtre. Essayez depuis la barre '
            'des tâches Windows.', _capabilities.supported), false);

  Future<void> startWindowDrag() => _enqueue<void>(() async {
        await _windowAction('startWindowDrag',
            'Impossible de déplacer la fenêtre. Relâchez puis faites glisser '
            'à nouveau son en-tête.', _capabilities.dragWindow);
      }, null);

  @override
  void dispose() {
    _disposed = true;
    _retryAction = null;
    super.dispose();
  }
}
