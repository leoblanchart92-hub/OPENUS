import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/nexus_colors.dart';
import '../services/update_service.dart';
import 'neon_glass_card.dart';

class UpdateCard extends StatefulWidget {
  const UpdateCard({super.key});

  @override
  State<UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends State<UpdateCard> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkForUpdates(silent: true);
    });
  }

  Future<void> _checkForUpdates({bool silent = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final update = await UpdateService.checkForUpdate();
      if (!mounted) return;
      if (update == null) {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nexus AI est déjà à jour.')),
          );
        }
        return;
      }

      final install = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Mise à jour disponible'),
          content: Text(
            'Nexus AI ${update.version} est disponible. L’installateur sera '
            'téléchargé puis lancé. L’application se fermera pendant la mise à jour.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Plus tard'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Installer'),
            ),
          ],
        ),
      );
      if (install == true) await UpdateService.installUpdate(update);
    } catch (error) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mise à jour impossible : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) => NeonGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.system_update_alt_rounded,
                  color: NexusColors.lavenderGlow,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mises à jour',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  'v${UpdateService.currentVersion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              Platform.isWindows
                  ? 'Nexus vérifie automatiquement les nouvelles versions au démarrage. Vous pouvez aussi lancer une recherche manuelle. '
                      'Si une mise à jour est disponible, elle sera installée après confirmation.'
                  : 'La vérification et l’installation automatiques sont disponibles sur Windows.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: Platform.isWindows && !_checking
                    ? _checkForUpdates
                    : null,
                icon: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  _checking ? 'Vérification…' : 'Rechercher une mise à jour',
                ),
              ),
            ),
          ],
        ),
      );
}