import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_info.dart';
import '../../core/theme/openus_theme.dart';

/// Drop the supplied logo at assets/branding/openus_logo.png and restart.
/// Until then this is a provisional geometric mark, not the official logo.
class BrandMark extends StatefulWidget {
  const BrandMark({super.key, this.size = 40});
  final double size;
  @override
  State<BrandMark> createState() => _BrandMarkState();
}
class _BrandMarkState extends State<BrandMark> {
  bool _hasAsset = false;
  @override
  void initState() { super.initState(); _checkAsset(); }
  Future<void> _checkAsset() async {
    try { await rootBundle.load(AppInfo.logoAsset); if (mounted) setState(() => _hasAsset = true); }
    catch (_) { /* The optional official logo has not been supplied yet. */ }
  }
  @override
  Widget build(BuildContext context) => SizedBox(width: widget.size, height: widget.size,
    child: _hasAsset ? Image.asset(AppInfo.logoAsset, fit: BoxFit.contain,
      errorBuilder: (_, _, _) => CustomPaint(painter: _MarkPainter(Theme.of(context).colorScheme.primary)))
      : CustomPaint(painter: _MarkPainter(Theme.of(context).colorScheme.primary)));
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..strokeJoin = JoinStyle.round
      ..shader = LinearGradient(colors: [color, OpenUsColors.blue]).createShader(const Rect.fromLTWH(0, 0, 48, 48));
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = i * 3.141592653589793 / 3 - 3.141592653589793 / 2;
      final point = Offset(24 + 19 * math.cos(angle), 24 + 19 * math.sin(angle));
      if (i == 0) { path.moveTo(point.dx, point.dy); } else { path.lineTo(point.dx, point.dy); }
    }
    path.close(); canvas.drawPath(path, paint);
    canvas.drawArc(const Rect.fromLTWH(15, 15, 18, 18), -.6, 4.9, false, paint..strokeWidth = 3);
    canvas.drawLine(const Offset(29, 32), const Offset(34, 37), paint);
  }
  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    BrandMark(size: compact ? 30 : 40), const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(AppInfo.name, style: TextStyle(fontSize: compact ? 17 : 21, fontWeight: FontWeight.w700, letterSpacing: 4)),
      if (!compact) const SizedBox(height: 3),
      if (!compact) const Text(AppInfo.slogan, style: TextStyle(fontSize: 8, color: OpenUsColors.muted, letterSpacing: 2.1)),
    ]),
  ]);
}
