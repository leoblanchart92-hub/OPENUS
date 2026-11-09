import '../ai/groq_ai_contract.dart';
import '../companion/companion_state.dart';

/// Immutable user preferences for Nexus AI.
class AppSettings {
  const AppSettings({
    this.showInAppFloatingCompanion = true,
    this.showOrbitalAura = true,
    this.glowIntensity = 0.82,
    this.reducedMotion = false,
    this.paletteId = CompanionPaletteId.neonViolet,
    this.preferredGroqModelId = GroqConfig.defaultModelId,
  });

  final bool showInAppFloatingCompanion;
  final bool showOrbitalAura;
  final double glowIntensity;
  final bool reducedMotion;
  final CompanionPaletteId paletteId;
  final String preferredGroqModelId;

  AppSettings copyWith({
    bool? showInAppFloatingCompanion,
    bool? showOrbitalAura,
    double? glowIntensity,
    bool? reducedMotion,
    CompanionPaletteId? paletteId,
    String? preferredGroqModelId,
  }) {
    return AppSettings(
      showInAppFloatingCompanion:
          showInAppFloatingCompanion ?? this.showInAppFloatingCompanion,
      showOrbitalAura: showOrbitalAura ?? this.showOrbitalAura,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      paletteId: paletteId ?? this.paletteId,
      preferredGroqModelId: preferredGroqModelId ?? this.preferredGroqModelId,
    );
  }
}
