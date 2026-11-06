import 'ai.dart';

enum AccentChoice { violet, blue }

class AppSettings {
  const AppSettings({
    this.mode = AiMode.automatic,
    this.localEndpoint = 'http://127.0.0.1:11434',
    this.localModel = '',
    this.provider = CloudProvider.openAi,
    this.openAiModel = '',
    this.anthropicModel = '',
    this.contextMessages = 20,
    this.systemPrompt =
        'Tu es OPENUS, un assistant personnel francophone. Réponds avec précision et simplicité. '
        'Si tu ne sais pas, dis-le. Tu ne peux effectuer aucune action sur cet appareil pour le moment.',
    this.autoSpeak = false,
    this.voiceLocale = 'fr-FR',
    this.speechRate = 0.5,
    this.accent = AccentChoice.violet,
    this.glowEnabled = true,
    this.reduceMotion = false,
  });

  final AiMode mode;
  final String localEndpoint;
  final String localModel;
  final CloudProvider provider;
  final String openAiModel;
  final String anthropicModel;
  final int contextMessages;
  final String systemPrompt;
  final bool autoSpeak;
  final String voiceLocale;
  final double speechRate;
  final AccentChoice accent;
  final bool glowEnabled;
  final bool reduceMotion;

  String get cloudModel =>
      provider == CloudProvider.openAi ? openAiModel : anthropicModel;
  bool get localConfigured =>
      localModel.trim().isNotEmpty && endpointError == null;
  bool get cloudConfigured => cloudModel.trim().isNotEmpty;
  bool get anyEngineConfigured => localConfigured || cloudConfigured;

  /// Syntactic validation only: never claims that a server is reachable.
  String? get endpointError {
    try {
      final uri = Uri.parse(localEndpoint.trim());
      if (!uri.hasAuthority ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.query.isNotEmpty ||
          uri.hasFragment ||
          (uri.path.isNotEmpty && uri.path != '/')) {
        return 'Utilisez une origine sans chemin, identifiants ni paramètres.';
      }
      if (uri.scheme == 'https') return null;
      if (uri.scheme != 'http') return 'Seuls HTTP et HTTPS sont acceptés.';
      final host = uri.host.toLowerCase();
      final parts = host.split('.');
      final octets = parts.length == 4
          ? parts.map(int.tryParse).toList()
          : <int?>[];
      final isIpv4 = octets.length == 4 && !octets.contains(null);
      if (isIpv4) {
        final a = octets[0]!, b = octets[1]!;
        if (octets.any((n) => n < 0 || n > 255))
          return 'Adresse IPv4 invalide.';
        if (a == 127 ||
            a == 10 ||
            (a == 172 && b >= 16 && b <= 31) ||
            (a == 192 && b == 168) ||
            (a == 169 && b == 254))
          return null;
      }
      if (host == 'localhost' ||
          host == '::1' ||
          host == '[::1]' ||
          !host.contains('.') ||
          host.endsWith('.local') ||
          host.endsWith('.lan'))
        return null;
      return 'HTTP est réservé au réseau local. Utilisez HTTPS pour un serveur distant.';
    } on FormatException {
      return 'Adresse invalide. Exemple : http://127.0.0.1:11434';
    }
  }

  AppSettings copyWith({
    AiMode? mode,
    String? localEndpoint,
    String? localModel,
    CloudProvider? provider,
    String? openAiModel,
    String? anthropicModel,
    int? contextMessages,
    String? systemPrompt,
    bool? autoSpeak,
    String? voiceLocale,
    double? speechRate,
    AccentChoice? accent,
    bool? glowEnabled,
    bool? reduceMotion,
  }) => AppSettings(
    mode: mode ?? this.mode,
    localEndpoint: localEndpoint ?? this.localEndpoint,
    localModel: localModel ?? this.localModel,
    provider: provider ?? this.provider,
    openAiModel: openAiModel ?? this.openAiModel,
    anthropicModel: anthropicModel ?? this.anthropicModel,
    contextMessages: contextMessages ?? this.contextMessages,
    systemPrompt: systemPrompt ?? this.systemPrompt,
    autoSpeak: autoSpeak ?? this.autoSpeak,
    voiceLocale: voiceLocale ?? this.voiceLocale,
    speechRate: speechRate ?? this.speechRate,
    accent: accent ?? this.accent,
    glowEnabled: glowEnabled ?? this.glowEnabled,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'localEndpoint': localEndpoint,
    'localModel': localModel,
    'provider': provider.name,
    'openAiModel': openAiModel,
    'anthropicModel': anthropicModel,
    'contextMessages': contextMessages,
    'systemPrompt': systemPrompt,
    'autoSpeak': autoSpeak,
    'voiceLocale': voiceLocale,
    'speechRate': speechRate,
    'accent': accent.name,
    'glowEnabled': glowEnabled,
    'reduceMotion': reduceMotion,
  };

  /// Unknown/corrupt individual preferences fall back, never to a fake API key.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const defaults = AppSettings();
    T enumValue<T extends Enum>(String key, List<T> values, T fallback) {
      final name = json[key];
      return values.where((v) => v.name == name).firstOrNull ?? fallback;
    }

    String text(String key, String fallback, int max) {
      final value = json[key];
      return value is String && value.length <= max ? value : fallback;
    }

    return AppSettings(
      mode: enumValue('mode', AiMode.values, defaults.mode),
      localEndpoint: text('localEndpoint', defaults.localEndpoint, 2048),
      localModel: text('localModel', '', 200),
      provider: enumValue('provider', CloudProvider.values, defaults.provider),
      openAiModel: text('openAiModel', '', 200),
      anthropicModel: text('anthropicModel', '', 200),
      contextMessages:
          (json['contextMessages'] as num?)?.clamp(4, 40).toInt() ?? 20,
      systemPrompt: text('systemPrompt', defaults.systemPrompt, 4000),
      autoSpeak: json['autoSpeak'] as bool? ?? false,
      voiceLocale: text('voiceLocale', 'fr-FR', 32),
      speechRate:
          (json['speechRate'] as num?)?.clamp(0.3, 0.7).toDouble() ?? 0.5,
      accent: enumValue('accent', AccentChoice.values, defaults.accent),
      glowEnabled: json['glowEnabled'] as bool? ?? true,
      reduceMotion: json['reduceMotion'] as bool? ?? false,
    );
  }
}
