import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/nexus_colors.dart';
import 'companion_state.dart';

/// Custom vector painter rendering **Nyx**, the original Nexus AI companion.
///
/// Visual anatomy (original design, distinct from Coucou's Mochi):
/// - Layered ambient neon-violet radial aura
/// - Tilted elliptical orbital telemetry ring with moving light nodes
/// - Twin floating articulated cyber-stabilizer fins
/// - Sculpted dark obsidian pod chassis with metallic violet rim
/// - Curved holographic visor displaying expressive eyes, natural blinks,
///   cursor/touch gaze tracking, scanlines, and animated voice waveforms.
class NexusCompanionPainter extends CustomPainter {
  NexusCompanionPainter({
    required this.phase,
    required this.reactionProgress,
    required this.state,
    required this.profile,
    required this.mood,
    required this.palette,
    required this.gazeOffset,
    required this.glowIntensity,
    required this.showOrbitalAura,
    required this.reducedMotion,
  });

  /// Continuous normalized loop [0..1) driving breathing, orbit, blink, wave.
  final double phase;

  /// One-shot impulse [0..1] when Nyx reacts to a tap or sent message.
  final double reactionProgress;

  final CompanionState state;
  final CompanionBehaviorProfile profile;
  final CompanionMood mood;
  final CompanionPalette palette;
  final Offset gazeOffset;
  final double glowIntensity;
  final bool showOrbitalAura;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);

    final twoPi = math.pi * 2;
    final motionScale = reducedMotion ? 0.25 : 1.0;

    final hoverWave = math.sin(phase * twoPi * profile.hoverCycles);
    final hoverY =
        hoverWave * unit * profile.hoverAmplitude * motionScale;

    final swayX = state == CompanionState.waiting
        ? math.sin(phase * twoPi) * unit * 0.025 * motionScale
        : 0.0;

    final reactionBounce =
        math.sin(reactionProgress * math.pi) * unit * 0.045 * motionScale;
    final headCenter = center + Offset(swayX, hoverY - reactionBounce);

    final headW = unit * 0.56;
    final headH = unit * 0.48;

    // 1. Ambient radial neon glow
    final glowAlpha =
        (0.28 * glowIntensity * profile.auraScale).clamp(0.08, 0.55);
    final auraRadius = unit * 0.48 * profile.auraScale;
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.accent.alphaFactor(glowAlpha),
          palette.primary.alphaFactor(glowAlpha * 0.48),
          Colors.transparent,
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(Rect.fromCircle(center: headCenter, radius: auraRadius));
    canvas.drawCircle(headCenter, auraRadius, auraPaint);

    // 2. Reaction ripple wave
    if (reactionProgress > 0.01 && reactionProgress < 0.99) {
      final rippleRadius = unit * (0.28 + reactionProgress * 0.22);
      final rippleAlpha = (1.0 - reactionProgress) * 0.65 * glowIntensity;
      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, unit * 0.014 * (1.0 - reactionProgress))
        ..color = palette.highlight.alphaFactor(rippleAlpha);
      canvas.drawCircle(headCenter, rippleRadius, ripplePaint);
    }

    // 3. Back orbital ring half & telemetry nodes
    if (showOrbitalAura) {
      _paintOrbitalRing(
        canvas,
        headCenter,
        unit,
        profile,
        twoPi,
        motionScale,
        backHalf: true,
      );
    }

    // 4. Twin floating stabilizer cyber-fins
    _paintStabilizerFins(
      canvas,
      headCenter,
      headW,
      headH,
      unit,
      profile,
      twoPi,
      motionScale,
    );

    // 5. Obsidian sculpted chassis
    _paintChassis(canvas, headCenter, headW, headH, unit);

    // 6. Curved holographic visor & facial features
    _paintVisorAndFace(
      canvas,
      headCenter,
      headW,
      headH,
      unit,
      profile,
      twoPi,
      motionScale,
    );

    // 7. Front orbital ring arc (creates crisp 3D depth crossing around Nyx)
    if (showOrbitalAura) {
      _paintOrbitalRing(
        canvas,
        headCenter,
        unit,
        profile,
        twoPi,
        motionScale,
        backHalf: false,
      );
    }
  }

  void _paintOrbitalRing(
    Canvas canvas,
    Offset headCenter,
    double unit,
    CompanionBehaviorProfile profile,
    double twoPi,
    double motionScale, {
    required bool backHalf,
  }) {
    final orbitRx = unit * 0.42;
    final orbitRy = unit * 0.145;
    final tilt = -0.26 +
        math.sin(phase * twoPi) * 0.05 * motionScale +
        (state == CompanionState.thinking ? 0.12 : 0.0);

    canvas.save();
    canvas.translate(headCenter.dx, headCenter.dy + unit * 0.02);
    canvas.rotate(tilt);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: orbitRx * 2,
      height: orbitRy * 2,
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, unit * 0.011)
      ..strokeCap = StrokeCap.round
      ..color = palette.accent.alphaFactor(
        (backHalf ? 0.22 : 0.62) * glowIntensity,
      );

    if (backHalf) {
      canvas.drawArc(rect, math.pi, math.pi, false, ringPaint);
    } else {
      canvas.drawArc(rect, 0, math.pi, false, ringPaint);
    }

    // Orbiting neural light nodes (use integer cycle speed for seamless loop)
    final speed = reducedMotion ? 1.0 : profile.haloSpeedMultiplier;
    for (var i = 0; i < profile.particleCount; i++) {
      final angle =
          (phase * twoPi * speed) + (i * twoPi / profile.particleCount);
      final isFrontSide = math.sin(angle) >= 0;
      if (isFrontSide == !backHalf) {
        final px = math.cos(angle) * orbitRx;
        final py = math.sin(angle) * orbitRy;
        final nodeRadius = unit * (i == 0 ? 0.021 : 0.015);
        final nodeGlow = Paint()
          ..color = palette.primary.alphaFactor(0.45 * glowIntensity);
        final nodeCore = Paint()
          ..color = palette.highlight.alphaFactor(0.95);
        canvas.drawCircle(Offset(px, py), nodeRadius * 2.1, nodeGlow);
        canvas.drawCircle(Offset(px, py), nodeRadius, nodeCore);
      }
    }

    canvas.restore();
  }

  void _paintStabilizerFins(
    Canvas canvas,
    Offset headCenter,
    double headW,
    double headH,
    double unit,
    CompanionBehaviorProfile profile,
    double twoPi,
    double motionScale,
  ) {
    final flutter = math.sin(phase * twoPi * 2) * 0.04 * motionScale;
    final baseTilt = profile.finTiltRadians +
        (mood == CompanionMood.curious ? 0.10 : 0.0) +
        flutter;

    for (final side in [-1.0, 1.0]) {
      final asymmetricTilt =
          (state == CompanionState.waiting || mood == CompanionMood.curious) &&
                  side > 0
              ? baseTilt * 1.45
              : baseTilt;

      canvas.save();
      final anchor = Offset(
        headCenter.dx + side * (headW * 0.54),
        headCenter.dy - headH * 0.06,
      );
      canvas.translate(anchor.dx, anchor.dy);
      canvas.rotate(side * asymmetricTilt);

      final finW = unit * 0.075;
      final finH = unit * 0.22;
      final finPath = Path()
        ..moveTo(0, -finH * 0.55)
        ..quadraticBezierTo(side * finW * 1.15, -finH * 0.2, side * finW * 0.85,
            finH * 0.45)
        ..quadraticBezierTo(side * finW * 0.2, finH * 0.65, -side * finW * 0.1,
            finH * 0.25)
        ..close();

      final finFill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.chassisBase,
            const Color(0xFF07060E),
          ],
        ).createShader(Rect.fromLTWH(-finW, -finH, finW * 2, finH * 2));

      final finBorder = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, unit * 0.011)
        ..color = palette.primary.alphaFactor(0.75 * glowIntensity);

      canvas.drawPath(finPath, finFill);
      canvas.drawPath(finPath, finBorder);

      // Inner neon accent strip inside each stabilizer fin
      final stripPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.2, unit * 0.013)
        ..color = palette.accent.alphaFactor(0.85 * glowIntensity);
      canvas.drawLine(
        Offset(side * finW * 0.42, -finH * 0.28),
        Offset(side * finW * 0.48, finH * 0.24),
        stripPaint,
      );

      canvas.restore();
    }
  }

  void _paintChassis(
    Canvas canvas,
    Offset headCenter,
    double headW,
    double headH,
    double unit,
  ) {
    final headRect = Rect.fromCenter(
      center: headCenter,
      width: headW,
      height: headH,
    );

    // Sculpted futuristic hexagonal-capsule silhouette (distinct from round blobs)
    final rrect = RRect.fromRectAndCorners(
      headRect,
      topLeft: Radius.circular(headH * 0.46),
      topRight: Radius.circular(headH * 0.46),
      bottomLeft: Radius.circular(headH * 0.36),
      bottomRight: Radius.circular(headH * 0.36),
    );

    final chassisShadow = Paint()
      ..color = palette.primary.alphaFactor(0.24 * glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.045);
    canvas.drawRRect(rrect, chassisShadow);

    final chassisFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          palette.chassisBase,
          const Color(0xFF080711),
          const Color(0xFF140F28),
        ],
      ).createShader(headRect);
    canvas.drawRRect(rrect, chassisFill);

    // Crisp rim highlight
    final chassisBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, unit * 0.014)
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.highlight.alphaFactor(0.65),
          palette.primary.alphaFactor(0.75 * glowIntensity),
          palette.primary.alphaFactor(0.25),
        ],
      ).createShader(headRect);
    canvas.drawRRect(rrect, chassisBorder);

    // Subtle top crown status node
    final crownCenter = Offset(headCenter.dx, headRect.top + unit * 0.025);
    final crownGlow = Paint()
      ..color = palette.accent.alphaFactor(0.55 * glowIntensity);
    final crownCore = Paint()..color = palette.highlight;
    canvas.drawCircle(crownCenter, unit * 0.022, crownGlow);
    canvas.drawCircle(crownCenter, unit * 0.009, crownCore);
  }

  void _paintVisorAndFace(
    Canvas canvas,
    Offset headCenter,
    double headW,
    double headH,
    double unit,
    CompanionBehaviorProfile profile,
    double twoPi,
    double motionScale,
  ) {
    final visorRect = Rect.fromCenter(
      center: headCenter + Offset(0, headH * 0.04),
      width: headW * 0.80,
      height: headH * 0.64,
    );
    final visorRRect = RRect.fromRectAndRadius(
      visorRect,
      Radius.circular(headH * 0.24),
    );

    final visorBg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF05040B),
          Color(0xFF0D091D),
        ],
      ).createShader(visorRect);
    canvas.drawRRect(visorRRect, visorBg);

    final visorBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, unit * 0.009)
      ..color = palette.primary.alphaFactor(0.52 * glowIntensity);
    canvas.drawRRect(visorRRect, visorBorder);

    // Thinking scanline sweep inside clipped visor
    if (state == CompanionState.thinking) {
      canvas.save();
      canvas.clipRRect(visorRRect);
      final scanX = visorRect.left +
          ((phase * 2) % 1.0) * (visorRect.width + unit * 0.12) -
          unit * 0.06;
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            palette.accent.alphaFactor(0.28 * glowIntensity),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(scanX, visorRect.top, unit * 0.12, visorRect.height),
        );
      canvas.drawRect(
        Rect.fromLTWH(scanX, visorRect.top, unit * 0.12, visorRect.height),
        scanPaint,
      );
      canvas.restore();
    }

    // Gaze offset inside visor
    final look = Offset(
      gazeOffset.dx * visorRect.width * 0.075,
      gazeOffset.dy * visorRect.height * 0.065,
    );

    // Natural blink curve: brief blink around phase 0.90..0.96
    var blinkFactor = 1.0;
    if (!reducedMotion && state != CompanionState.reacting) {
      if (phase > 0.90 && phase < 0.96) {
        final t = (phase - 0.90) / 0.06;
        blinkFactor = 1.0 - math.sin(t * math.pi) * 0.88;
      }
    }

    final eyeSpacing = visorRect.width * 0.23;
    final eyeY = visorRect.center.dy - visorRect.height * 0.08;
    final eyeRadiusX = visorRect.width * 0.095;
    final eyeRadiusY = visorRect.height * 0.145 * blinkFactor;

    final leftEyeCenter = Offset(visorRect.center.dx - eyeSpacing, eyeY) + look;
    final rightEyeCenter =
        Offset(visorRect.center.dx + eyeSpacing, eyeY) + look;

    _paintEyes(
      canvas,
      leftEyeCenter,
      rightEyeCenter,
      eyeRadiusX,
      eyeRadiusY,
      unit,
      blinkFactor,
    );

    // Subtle glowing cheek nodes when happy, playful, or speaking
    if (mood == CompanionMood.happy ||
        mood == CompanionMood.playful ||
        state == CompanionState.speaking ||
        state == CompanionState.reacting) {
      final cheekPaint = Paint()
        ..color = palette.accent.alphaFactor(0.45 * glowIntensity);
      final cheekOffsetY = visorRect.center.dy + visorRect.height * 0.14;
      canvas.drawCircle(
        Offset(visorRect.center.dx - eyeSpacing * 1.38, cheekOffsetY) +
            look * 0.3,
        unit * 0.015,
        cheekPaint,
      );
      canvas.drawCircle(
        Offset(visorRect.center.dx + eyeSpacing * 1.38, cheekOffsetY) +
            look * 0.3,
        unit * 0.015,
        cheekPaint,
      );
    }

    // Mouth / telemetry / voice waveform
    final mouthCenter =
        Offset(visorRect.center.dx, visorRect.center.dy + visorRect.height * 0.22) +
            look * 0.35;
    _paintMouth(
      canvas,
      mouthCenter,
      visorRect.width * 0.34,
      visorRect.height * 0.16,
      unit,
      profile,
      twoPi,
      motionScale,
    );
  }

  void _paintEyes(
    Canvas canvas,
    Offset leftCenter,
    Offset rightCenter,
    double rx,
    double ry,
    double unit,
    double blinkFactor,
  ) {
    final eyeGlowPaint = Paint()
      ..color = palette.accent.alphaFactor(0.48 * glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.025);

    final joyfulArcEyes = (state == CompanionState.reacting ||
            mood == CompanionMood.happy ||
            mood == CompanionMood.playful) &&
        blinkFactor > 0.5;

    for (var idx = 0; idx < 2; idx++) {
      final c = idx == 0 ? leftCenter : rightCenter;

      if (joyfulArcEyes && !(mood == CompanionMood.playful && idx == 1)) {
        // Cheerful luminous crescent arcs
        final arcPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(2.2, unit * 0.024)
          ..color = palette.highlight;
        final arcGlow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(4.0, unit * 0.042)
          ..color = palette.accent.alphaFactor(0.55 * glowIntensity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.018);

        final path = Path()
          ..moveTo(c.dx - rx * 0.95, c.dy + ry * 0.22)
          ..quadraticBezierTo(c.dx, c.dy - ry * 0.85, c.dx + rx * 0.95, c.dy + ry * 0.22);
        canvas.drawPath(path, arcGlow);
        canvas.drawPath(path, arcPaint);
      } else {
        // Analytical / attentive rounded visor eyes
        final scaleY = state == CompanionState.thinking
            ? 0.58
            : (mood == CompanionMood.curious && idx == 1 ? 0.78 : 1.0);
        final eyeRect = Rect.fromCenter(
          center: c,
          width: rx * 1.75,
          height: math.max(unit * 0.012, ry * 2.0 * scaleY),
        );
        final eyeRRect = RRect.fromRectAndRadius(
          eyeRect,
          Radius.circular(rx),
        );
        final eyeFillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.highlight,
              palette.accent,
            ],
          ).createShader(eyeRect);
        canvas.drawRRect(eyeRRect, eyeGlowPaint);
        canvas.drawRRect(eyeRRect, eyeFillPaint);

        // Specular iris highlight when eyes are open
        if (blinkFactor > 0.5 && state != CompanionState.thinking) {
          final glintPaint = Paint()
            ..color = Colors.white.alphaFactor(0.85);
          canvas.drawCircle(
            Offset(c.dx - rx * 0.28, c.dy - ry * 0.3 * scaleY),
            math.max(1.0, unit * 0.011),
            glintPaint,
          );
        }
      }
    }
  }

  void _paintMouth(
    Canvas canvas,
    Offset center,
    double width,
    double maxHeight,
    double unit,
    CompanionBehaviorProfile profile,
    double twoPi,
    double motionScale,
  ) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.6, unit * 0.016)
      ..color = palette.highlight.alphaFactor(0.92);

    if (state == CompanionState.speaking) {
      // 7-bar reactive holographic voice equalizer
      const bars = 7;
      final barSpacing = width / (bars - 1);
      final barPaint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(2.0, unit * 0.016)
        ..color = palette.highlight;

      for (var i = 0; i < bars; i++) {
        final x = center.dx - width / 2 + i * barSpacing;
        final envelope = 1.0 - ((i - 3).abs() / 3.8);
        final wave = 0.35 +
            0.65 *
                ((math.sin(phase * twoPi * 5 + i * 1.15) + 1.0) / 2.0);
        final h = maxHeight * 1.3 * envelope * wave * (reducedMotion ? 0.5 : 1.0);
        canvas.drawLine(
          Offset(x, center.dy - h / 2),
          Offset(x, center.dy + h / 2),
          barPaint,
        );
      }
      return;
    }

    if (state == CompanionState.thinking) {
      // Animated 3-dot neural pulse wave
      for (var i = 0; i < 3; i++) {
        final dx = (i - 1) * (width * 0.28);
        final pulse = (math.sin(phase * twoPi * 3 - i * 0.9) + 1.0) / 2.0;
        final r = unit * (0.011 + 0.008 * pulse);
        final dotPaint = Paint()
          ..color = palette.highlight.alphaFactor(0.45 + 0.55 * pulse);
        canvas.drawCircle(
          Offset(center.dx + dx, center.dy - pulse * unit * 0.012 * motionScale),
          r,
          dotPaint,
        );
      }
      return;
    }

    if (state == CompanionState.reacting || mood == CompanionMood.happy) {
      // Joyful glowing open smile arc
      final path = Path()
        ..moveTo(center.dx - width * 0.34, center.dy - maxHeight * 0.15)
        ..quadraticBezierTo(
          center.dx,
          center.dy + maxHeight * 0.85,
          center.dx + width * 0.34,
          center.dy - maxHeight * 0.15,
        );
      canvas.drawPath(path, strokePaint);
      return;
    }

    // Idle / waiting serene subtle smile
    final smileDepth = state == CompanionState.waiting ? 0.42 : 0.35;
    final path = Path()
      ..moveTo(center.dx - width * 0.26, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy + maxHeight * smileDepth,
        center.dx + width * 0.26,
        center.dy,
      );
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant NexusCompanionPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.reactionProgress != reactionProgress ||
        oldDelegate.state != state ||
        oldDelegate.profile.finTiltRadians != profile.finTiltRadians ||
        oldDelegate.profile.auraScale != profile.auraScale ||
        oldDelegate.profile.hoverAmplitude != profile.hoverAmplitude ||
        oldDelegate.profile.particleCount != profile.particleCount ||
        oldDelegate.mood != mood ||
        oldDelegate.palette.name != palette.name ||
        oldDelegate.gazeOffset != gazeOffset ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.showOrbitalAura != showOrbitalAura ||
        oldDelegate.reducedMotion != reducedMotion;
  }
}
