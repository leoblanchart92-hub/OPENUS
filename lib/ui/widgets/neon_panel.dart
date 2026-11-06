import 'package:flutter/material.dart';
import '../../core/theme/openus_theme.dart';

class NeonPanel extends StatelessWidget {
  const NeonPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.glow = false,
    this.accent,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: OpenUsColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: glow ? color.withValues(alpha: .32) : OpenUsColors.border,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: glow ? .065 : .025),
            OpenUsColors.surface,
          ],
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: .065),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.eyebrow,
    this.title, {
    super.key,
    this.description,
    this.trailing,
  });
  final String eyebrow;
  final String title;
  final String? description;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: const TextStyle(
                    color: OpenUsColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.action,
    this.warning = false,
  });
  final String message;
  final Widget? action;
  final bool warning;
  @override
  Widget build(BuildContext context) {
    final color = warning
        ? OpenUsColors.warning
        : Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        border: Border.all(color: color.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}
