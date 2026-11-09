import 'package:flutter/material.dart';

/// Top-level navigation destinations shared across desktop sidebar and
/// mobile bottom navigation.
enum NexusDestination {
  home(
    label: 'Accueil',
    mobileLabel: 'Accueil',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  conversations(
    label: 'Conversations',
    mobileLabel: 'Chat',
    icon: Icons.chat_bubble_outline_rounded,
    activeIcon: Icons.chat_bubble_rounded,
  ),
  history(
    label: 'Historique',
    mobileLabel: 'Historique',
    icon: Icons.history_rounded,
    activeIcon: Icons.history_rounded,
  ),
  companion(
    label: 'Compagnon',
    mobileLabel: 'Nyx',
    icon: Icons.auto_awesome_outlined,
    activeIcon: Icons.auto_awesome_rounded,
  ),
  settings(
    label: 'Paramètres',
    mobileLabel: 'Réglages',
    icon: Icons.tune_outlined,
    activeIcon: Icons.tune_rounded,
  );

  const NexusDestination({
    required this.label,
    required this.mobileLabel,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final String mobileLabel;
  final IconData icon;
  final IconData activeIcon;
}
