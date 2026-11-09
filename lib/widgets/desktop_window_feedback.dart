import 'package:flutter/material.dart';

import '../services/desktop_window_service.dart';

/// Uses the existing SnackBar theme; native error text never enters the UI.
class DesktopWindowFeedback extends StatefulWidget {
  const DesktopWindowFeedback({
    super.key,
    required this.service,
    required this.child,
  });

  final DesktopWindowService service;
  final Widget child;

  @override
  State<DesktopWindowFeedback> createState() => _DesktopWindowFeedbackState();
}

class _DesktopWindowFeedbackState extends State<DesktopWindowFeedback> {
  int _shownSequence = 0;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _feedback;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceChanged);
    _onServiceChanged();
  }

  @override
  void didUpdateWidget(covariant DesktopWindowFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      oldWidget.service.removeListener(_onServiceChanged);
      _shownSequence = 0;
      widget.service.addListener(_onServiceChanged);
      _onServiceChanged();
    }
  }

  void _onServiceChanged() {
    final service = widget.service;
    final sequence = service.errorSequence;
    if (service.lastStatusMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.service == service &&
            service.lastStatusMessage == null) {
          _feedback?.close();
          _feedback = null;
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
      return;
    }
    if (sequence == 0 || sequence == _shownSequence) {
      return;
    }
    _shownSequence = sequence;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.service != service ||
          service.errorSequence != sequence ||
          service.lastStatusMessage == null) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      _feedback?.close();
      _feedback = messenger.showSnackBar(SnackBar(
        content: Text(service.lastStatusMessage!),
        action: service.canRetry
            ? SnackBarAction(
                label: 'Réessayer',
                onPressed: () {
                  if (service.errorSequence == sequence) {
                    service.retryLastOperation();
                  }
                },
              )
            : null,
      ));
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
