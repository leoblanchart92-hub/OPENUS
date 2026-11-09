import 'package:flutter/material.dart';

import 'companion_controller.dart';
import 'companion_painter.dart';
import 'companion_state.dart';

/// Interactive animated widget displaying **Nyx**, the Nexus AI companion.
///
/// Tracks mouse hover on desktop and touch drags on mobile, triggers playful
/// reactions on tap, smoothly interpolates state transitions, and isolates
/// 60/120fps repaints inside a [RepaintBoundary].
class NexusCompanion extends StatefulWidget {
  const NexusCompanion({
    super.key,
    required this.controller,
    this.size = 160,
    this.interactive = true,
    this.trackPointer = true,
    this.onTapOverride,
  });

  final CompanionController controller;
  final double size;
  final bool interactive;
  final bool trackPointer;
  final VoidCallback? onTapOverride;

  @override
  State<NexusCompanion> createState() => _NexusCompanionState();
}

class _NexusCompanionState extends State<NexusCompanion>
    with TickerProviderStateMixin {
  late final AnimationController _loopController;
  late final AnimationController _reactionController;
  late final AnimationController _transitionController;

  late CompanionState _observedState;
  late CompanionBehaviorProfile _fromProfile;
  late CompanionBehaviorProfile _toProfile;
  int _lastPulseSeq = 0;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _reactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );

    _observedState = widget.controller.state;
    _fromProfile = CompanionBehaviorProfile.forState(_observedState);
    _toProfile = _fromProfile;
    _lastPulseSeq = widget.controller.reactionPulse;
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant NexusCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      _observedState = widget.controller.state;
      _fromProfile = CompanionBehaviorProfile.forState(_observedState);
      _toProfile = _fromProfile;
      _transitionController.value = 1.0;
      _lastPulseSeq = widget.controller.reactionPulse;
      widget.controller.addListener(_handleControllerChange);
    }
  }

  void _handleControllerChange() {
    if (!mounted) {
      return;
    }
    final nextState = widget.controller.state;
    if (nextState != _observedState) {
      final eased = Curves.easeOutCubic.transform(_transitionController.value);
      _fromProfile =
          CompanionBehaviorProfile.lerp(_fromProfile, _toProfile, eased);
      _toProfile = CompanionBehaviorProfile.forState(nextState);
      _observedState = nextState;
      _transitionController.forward(from: 0);
    }

    if (widget.controller.reactionPulse != _lastPulseSeq) {
      _lastPulseSeq = widget.controller.reactionPulse;
      _reactionController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _loopController.dispose();
    _reactionController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _updateGazeFromLocalPosition(Offset localPosition) {
    if (!widget.trackPointer) {
      return;
    }
    final half = widget.size / 2;
    if (half <= 0) {
      return;
    }
    final normalized = Offset(
      ((localPosition.dx - half) / half).clamp(-1.0, 1.0),
      ((localPosition.dy - half) / half).clamp(-1.0, 1.0),
    );
    widget.controller.updateGaze(normalized);
  }

  @override
  Widget build(BuildContext context) {
    Widget visual = RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _loopController,
          _reactionController,
          _transitionController,
          widget.controller,
        ]),
        builder: (context, _) {
          final ctrl = widget.controller;
          final eased =
              Curves.easeOutCubic.transform(_transitionController.value);
          final interpolatedProfile = CompanionBehaviorProfile.lerp(
            _fromProfile,
            _toProfile,
            eased,
          );
          return CustomPaint(
            size: Size.square(widget.size),
            painter: NexusCompanionPainter(
              phase: _loopController.value,
              reactionProgress: _reactionController.value,
              state: ctrl.state,
              profile: interpolatedProfile,
              mood: ctrl.mood,
              palette: ctrl.paletteId.palette,
              gazeOffset: ctrl.gazeOffset,
              glowIntensity: ctrl.glowIntensity,
              showOrbitalAura: ctrl.showOrbitalAura,
              reducedMotion: ctrl.reducedMotion,
            ),
          );
        },
      ),
    );

    if (widget.interactive) {
      visual = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTapOverride ?? widget.controller.tapCompanion,
        onPanUpdate: widget.trackPointer
            ? (details) => _updateGazeFromLocalPosition(details.localPosition)
            : null,
        onPanEnd: widget.trackPointer
            ? (_) => widget.controller.resetGaze()
            : null,
        child: visual,
      );
    }

    if (widget.trackPointer) {
      visual = MouseRegion(
        cursor: widget.interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onHover: (event) => _updateGazeFromLocalPosition(event.localPosition),
        onExit: (_) => widget.controller.resetGaze(),
        child: visual,
      );
    }

    return Semantics(
      label: 'Nyx, compagnon animé Nexus AI — ${widget.controller.state.label}',
      button: widget.interactive,
      child: SizedBox.square(
        dimension: widget.size,
        child: visual,
      ),
    );
  }
}
