import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/openus_theme.dart';
import '../../domain/ai.dart';
import '../../state/availability_controller.dart';
import '../../state/settings_controller.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.tooltip,
  });
  final String label;
  final Color color;
  final String? tooltip;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip ?? label,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class EngineStatusPill extends StatelessWidget {
  const EngineStatusPill({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    final availability = context.watch<AvailabilityController>();
    final local = availability[EngineKind.local];
    final cloudKind = settings.provider == CloudProvider.openAi
        ? EngineKind.openAi
        : EngineKind.anthropic;
    final cloud = availability[cloudKind];
    if (availability.busy) {
      return const StatusPill(label: 'Vérification…', color: OpenUsColors.blue);
    }
    if (settings.mode != AiMode.internet &&
        local.state == HealthState.available &&
        settings.localConfigured) {
      return StatusPill(
        label: 'Ollama disponible',
        color: OpenUsColors.success,
        tooltip: local.message,
      );
    }
    if (settings.mode != AiMode.local &&
        cloud.state == HealthState.available &&
        settings.cloudConfigured) {
      return StatusPill(
        label: 'API vérifiée',
        color: OpenUsColors.success,
        tooltip: cloud.message,
      );
    }
    final configured = switch (settings.mode) {
      AiMode.local => settings.localConfigured,
      AiMode.internet => settings.cloudConfigured,
      AiMode.automatic => settings.anyEngineConfigured,
    };
    return StatusPill(
      label: configured ? 'Moteur à vérifier' : 'Moteur non configuré',
      color: configured ? OpenUsColors.warning : OpenUsColors.muted,
      tooltip:
          'Une configuration ne garantit pas la disponibilité. Lancez une vérification dans les paramètres.',
    );
  }
}
