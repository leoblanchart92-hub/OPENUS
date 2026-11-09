import 'package:flutter/material.dart';

import '../core/theme/nexus_colors.dart';
import 'companion_controller.dart';
import 'nexus_companion.dart';

/// Sleek draggable in-app floating companion pill inspired by desktop buddy
/// overlays, allowing instant access to Nyx from any main screen.
class FloatingCompanionOverlay extends StatefulWidget {
  const FloatingCompanionOverlay({
    super.key,
    required this.controller,
    required this.onOpenCompanionStudio,
    required this.onOpenCompactMode,
    this.minBottomInset = 20,
  });

  final CompanionController controller;
  final VoidCallback onOpenCompanionStudio;
  final VoidCallback onOpenCompactMode;
  final double minBottomInset;

  @override
  State<FloatingCompanionOverlay> createState() =>
      _FloatingCompanionOverlayState();
}

class _FloatingCompanionOverlayState extends State<FloatingCompanionOverlay> {
  double _rightOffset = 20;
  late double _bottomOffset;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _bottomOffset = widget.minBottomInset;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxRight = (screenSize.width - 180).clamp(16.0, 2000.0);
    final minBottom = widget.minBottomInset;
    final maxBottom = (screenSize.height - 180).clamp(minBottom, 2000.0);

    return Positioned(
      right: _rightOffset.clamp(12.0, maxRight),
      bottom: _bottomOffset.clamp(minBottom, maxBottom),
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final palette = widget.controller.paletteId.palette;
          return GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rightOffset = (_rightOffset - details.delta.dx).clamp(
                  12.0,
                  maxRight,
                );
                _bottomOffset = (_bottomOffset - details.delta.dy).clamp(
                  minBottom,
                  maxBottom,
                );
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: _expanded ? 12 : 8,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: NexusColors.surfaceDark.alphaFactor(0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: palette.primary.alphaFactor(0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.alphaFactor(0.24),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NexusCompanion(
                    controller: widget.controller,
                    size: 56,
                    trackPointer: true,
                    onTapOverride: () {
                      widget.controller.tapCompanion();
                      setState(() => _expanded = !_expanded);
                    },
                  ),
                  if (_expanded) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Nyx • ${widget.controller.state.label}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: NexusColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MiniOverlayAction(
                              label: 'Studio',
                              onTap: () {
                                setState(() => _expanded = false);
                                widget.onOpenCompanionStudio();
                              },
                            ),
                            const SizedBox(width: 6),
                            _MiniOverlayAction(
                              label: 'Compact',
                              onTap: () {
                                setState(() => _expanded = false);
                                widget.onOpenCompactMode();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniOverlayAction extends StatelessWidget {
  const _MiniOverlayAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: NexusColors.neonViolet.alphaFactor(0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: NexusColors.neonViolet.alphaFactor(0.45),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: NexusColors.softVioletTint,
          ),
        ),
      ),
    );
  }
}
