import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/openus_theme.dart';
import '../../state/settings_controller.dart';

class AssistantOrb extends StatefulWidget {
  const AssistantOrb({super.key, this.size = 210, this.active = false});
  final double size;
  final bool active;
  @override
  State<AssistantOrb> createState() => _AssistantOrbState();
}

class _AssistantOrbState extends State<AssistantOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  bool _motionAllowed = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<SettingsController>().settings;
    _motionAllowed =
        !settings.reduceMotion && !MediaQuery.disableAnimationsOf(context);
    _controller.duration = widget.active
        ? const Duration(seconds: 3)
        : const Duration(seconds: 8);
    if (_motionAllowed) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didUpdateWidget(AssistantOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.active
        ? const Duration(seconds: 3)
        : const Duration(seconds: 8);
    if (_motionAllowed && !_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = context.select<SettingsController, bool>(
      (s) => s.settings.glowEnabled,
    );
    final accent = Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => CustomPaint(
            painter: _OrbPainter(
              _controller.value,
              accent,
              glow,
              widget.active,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter(this.time, this.accent, this.glow, this.active);
  final double time;
  final Color accent;
  final bool glow;
  final bool active;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 240;
    canvas.scale(scale, scale);
    final center = const Offset(120, 120);
    final angle = time * math.pi * 2;
    final pulse = .5 + .5 * math.sin(angle * 2);
    if (glow) {
      canvas.drawCircle(
        center,
        90,
        Paint()
          ..shader = RadialGradient(
            colors: [
              accent.withValues(alpha: .16 + pulse * .05),
              accent.withValues(alpha: .035),
              Colors.transparent,
            ],
            stops: const [0, .55, 1],
          ).createShader(Rect.fromCircle(center: center, radius: 90)),
      );
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7
      ..color = accent.withValues(alpha: .18);
    canvas.drawCircle(center, 106, line);
    canvas.drawCircle(
      center,
      86,
      line..color = OpenUsColors.blue.withValues(alpha: .18),
    );
    for (var i = 0; i < 60; i++) {
      final a = i * math.pi / 30;
      final inner = i % 5 == 0 ? 100.0 : 103.0;
      canvas.drawLine(
        center + Offset(math.cos(a) * inner, math.sin(a) * inner),
        center + Offset(math.cos(a) * 106, math.sin(a) * 106),
        line..color = accent.withValues(alpha: i % 5 == 0 ? .55 : .2),
      );
    }
    void arc(
      double radius,
      double start,
      double sweep,
      Color color,
      double width,
    ) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = color
          ..maskFilter = glow
              ? const MaskFilter.blur(BlurStyle.solid, 1.4)
              : null,
      );
    }

    arc(94, angle, math.pi * 1.15, accent.withValues(alpha: .85), 2);
    arc(
      94,
      angle + math.pi * 1.4,
      math.pi * .4,
      OpenUsColors.blue.withValues(alpha: .65),
      1.5,
    );
    arc(
      77,
      -angle * .7,
      math.pi * 1.4,
      OpenUsColors.blue.withValues(alpha: .7),
      1.5,
    );
    arc(68, angle * .4 + 1, math.pi * .9, accent.withValues(alpha: .4), .8);
    canvas.drawCircle(
      center,
      57,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.4, -.5),
          colors: [
            accent.withValues(alpha: .15),
            const Color(0xFF101322),
            OpenUsColors.background,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 57)),
    );
    canvas.drawCircle(
      center,
      57,
      line
        ..color = accent.withValues(alpha: .3)
        ..strokeWidth = 1,
    );
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 - math.pi / 2;
      final p = center + Offset(math.cos(a) * 29, math.sin(a) * 29);
      if (i == 0) {
        hex.moveTo(p.dx, p.dy);
      } else {
        hex.lineTo(p.dx, p.dy);
      }
    }
    hex.close();
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: .8),
    );
    canvas.drawCircle(
      center,
      17,
      line
        ..color = OpenUsColors.blue.withValues(alpha: .8)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      4,
      Paint()..color = OpenUsColors.text.withValues(alpha: .8),
    );
    for (var i = 0; i < 3; i++) {
      final a = angle + i * math.pi * 2 / 3;
      canvas.drawCircle(
        center + Offset(math.cos(a) * 94, math.sin(a) * 94),
        active ? 3 : 2,
        Paint()..color = i == 0 ? OpenUsColors.text : accent,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.accent != accent ||
      oldDelegate.glow != glow ||
      oldDelegate.active != active;
}
