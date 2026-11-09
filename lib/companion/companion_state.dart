import '../core/theme/nexus_colors.dart';

/// Primary operational animation states for Nyx, the Nexus AI companion.
enum CompanionState {
  idle(
    label: 'Repos',
    statusText: 'En veille attentive',
    description: 'Respiration douce, clignements naturels et orbite lente.',
  ),
  reacting(
    label: 'Réaction',
    statusText: 'Message reçu !',
    description: 'Impulsion lumineuse et rebond immédiat à l’envoi d’un message.',
  ),
  thinking(
    label: 'Réflexion',
    statusText: 'Analyse en cours...',
    description: 'Orbite accélérée, balayage de visière et nœuds neuronaux actifs.',
  ),
  speaking(
    label: 'Parole',
    statusText: 'Réponse active',
    description: 'Onde vocale synchronisée et expression lumineuse dynamique.',
  ),
  waiting(
    label: 'En attente',
    statusText: 'À votre écoute',
    description: 'Balancement curieux dans l’attente de votre prochain message.',
  );

  const CompanionState({
    required this.label,
    required this.statusText,
    required this.description,
  });

  final String label;
  final String statusText;
  final String description;
}

/// Facial expression nuances layered over the companion state.
enum CompanionMood {
  neutral('Neutre'),
  happy('Joyeux'),
  curious('Curieux'),
  focused('Concentré'),
  playful('Joueur');

  const CompanionMood(this.label);
  final String label;
}

/// Available visual theme presets for Nyx.
enum CompanionPaletteId {
  neonViolet,
  amethystPulse,
  midnightPrism;

  CompanionPalette get palette {
    switch (this) {
      case CompanionPaletteId.neonViolet:
        return CompanionPalette.neonViolet;
      case CompanionPaletteId.amethystPulse:
        return CompanionPalette.amethystPulse;
      case CompanionPaletteId.midnightPrism:
        return CompanionPalette.midnightPrism;
    }
  }
}

/// Data-driven animation parameters for each companion state.
///
/// Centralizing these parameters makes it straightforward to refine physics,
/// add new states, or connect external animation timelines later.
class CompanionBehaviorProfile {
  const CompanionBehaviorProfile({
    required this.hoverAmplitude,
    required this.hoverCycles,
    required this.haloSpeedMultiplier,
    required this.finTiltRadians,
    required this.auraScale,
    required this.particleCount,
    required this.mouthEnergy,
  });

  final double hoverAmplitude;
  final double hoverCycles;
  final double haloSpeedMultiplier;
  final double finTiltRadians;
  final double auraScale;
  final int particleCount;
  final double mouthEnergy;

  static CompanionBehaviorProfile lerp(
    CompanionBehaviorProfile a,
    CompanionBehaviorProfile b,
    double t,
  ) {
    final clamped = t.clamp(0.0, 1.0);
    return CompanionBehaviorProfile(
      hoverAmplitude:
          a.hoverAmplitude + (b.hoverAmplitude - a.hoverAmplitude) * clamped,
      hoverCycles: b.hoverCycles,
      haloSpeedMultiplier: b.haloSpeedMultiplier,
      finTiltRadians:
          a.finTiltRadians + (b.finTiltRadians - a.finTiltRadians) * clamped,
      auraScale: a.auraScale + (b.auraScale - a.auraScale) * clamped,
      particleCount: clamped < 0.5 ? a.particleCount : b.particleCount,
      mouthEnergy: a.mouthEnergy + (b.mouthEnergy - a.mouthEnergy) * clamped,
    );
  }

  static CompanionBehaviorProfile forState(CompanionState state) {
    switch (state) {
      case CompanionState.idle:
        return const CompanionBehaviorProfile(
          hoverAmplitude: 0.032,
          hoverCycles: 1.0,
          haloSpeedMultiplier: 1.0,
          finTiltRadians: 0.06,
          auraScale: 1.0,
          particleCount: 2,
          mouthEnergy: 0.15,
        );
      case CompanionState.reacting:
        return const CompanionBehaviorProfile(
          hoverAmplitude: 0.065,
          hoverCycles: 2.0,
          haloSpeedMultiplier: 2.0,
          finTiltRadians: 0.24,
          auraScale: 1.22,
          particleCount: 5,
          mouthEnergy: 0.85,
        );
      case CompanionState.thinking:
        return const CompanionBehaviorProfile(
          hoverAmplitude: 0.024,
          hoverCycles: 1.0,
          haloSpeedMultiplier: 3.0,
          finTiltRadians: -0.14,
          auraScale: 1.12,
          particleCount: 6,
          mouthEnergy: 0.55,
        );
      case CompanionState.speaking:
        return const CompanionBehaviorProfile(
          hoverAmplitude: 0.042,
          hoverCycles: 2.0,
          haloSpeedMultiplier: 2.0,
          finTiltRadians: 0.14,
          auraScale: 1.18,
          particleCount: 4,
          mouthEnergy: 1.0,
        );
      case CompanionState.waiting:
        return const CompanionBehaviorProfile(
          hoverAmplitude: 0.038,
          hoverCycles: 1.0,
          haloSpeedMultiplier: 1.0,
          finTiltRadians: 0.12,
          auraScale: 1.06,
          particleCount: 3,
          mouthEnergy: 0.25,
        );
    }
  }
}
