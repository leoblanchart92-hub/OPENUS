import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/openus_theme.dart';
import '../../../domain/ai.dart';
import '../../../domain/app_settings.dart';
import '../../../domain/local_model_profile.dart';
import '../../../state/availability_controller.dart';
import '../../../state/settings_controller.dart';
import '../../widgets/neon_panel.dart';

class EngineSettingsPage extends StatefulWidget {
  const EngineSettingsPage({super.key});
  @override
  State<EngineSettingsPage> createState() => _EngineSettingsPageState();
}

class _EngineSettingsPageState extends State<EngineSettingsPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _endpoint,
      _localModel,
      _openAiModel,
      _anthropicModel,
      _groqModel,
      _apiKey,
      _prompt;
  late AiMode _mode;
  late CloudProvider _provider;
  late int _contextMessages;
  late bool _lowMemory;
  bool _showKey = false;
  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsController>().settings;
    _mode = s.mode;
    _provider = s.provider;
    _contextMessages = s.contextMessages;
    _lowMemory = s.localLowMemoryMode;
    _endpoint = TextEditingController(text: s.localEndpoint);
    _localModel = TextEditingController(text: s.localModel);
    _openAiModel = TextEditingController(text: s.openAiModel);
    _anthropicModel = TextEditingController(text: s.anthropicModel);
    _groqModel = TextEditingController(text: s.groqModel);
    _prompt = TextEditingController(text: s.systemPrompt);
    _apiKey = TextEditingController();
  }

  @override
  void dispose() {
    for (final controller in [
      _endpoint,
      _localModel,
      _openAiModel,
      _anthropicModel,
      _groqModel,
      _apiKey,
      _prompt,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  AppSettings _draft() => context.read<SettingsController>().settings.copyWith(
    mode: _mode,
    localEndpoint: _endpoint.text.trim(),
    localModel: _localModel.text.trim(),
    localLowMemoryMode: _lowMemory,
    provider: _provider,
    openAiModel: _openAiModel.text.trim(),
    anthropicModel: _anthropicModel.text.trim(),
    groqModel: _groqModel.text.trim(),
    systemPrompt: _prompt.text.trim().isEmpty
        ? const AppSettings().systemPrompt
        : _prompt.text.trim(),
    contextMessages: _contextMessages,
  );

  void _selectProvider(CloudProvider provider) {
    setState(() {
      _provider = provider;
      _apiKey.clear();
      _showKey = false;
      final controller = switch (provider) {
        CloudProvider.openAi => _openAiModel,
        CloudProvider.anthropic => _anthropicModel,
        CloudProvider.groq => _groqModel,
      };
      if (controller.text.trim().isEmpty) {
        controller.text = provider.suggestedModel ?? '';
      }
    });
  }

  void _applyLightPreset() {
    setState(() {
      _localModel.text = LocalModelProfile.recommendedModel;
      _lowMemory = true;
      _contextMessages = LocalModelProfile.conversationMessages;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profil léger sélectionné. Installez le modèle dans Ollama, puis enregistrez et vérifiez.',
        ),
      ),
    );
  }

  Future<bool> _save({bool quiet = false}) async {
    if (!(_form.currentState?.validate() ?? false)) return false;
    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<SettingsController>().update(_draft());
    if (!mounted) return false;
    if (!quiet) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Configuration enregistrée. La disponibilité doit être vérifiée.'
                : 'Enregistrement impossible. Vérifiez le stockage.',
          ),
        ),
      );
    }
    return success;
  }

  Future<void> _test(EngineKind kind) async {
    if (!await _save(quiet: true) || !mounted) return;
    final settings = context.read<SettingsController>().settings;
    if (kind != EngineKind.local &&
        (!context.read<SettingsController>().hasKey(_provider) ||
            settings.cloudModel.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enregistrez une clé API et le nom exact du modèle avant de vérifier.',
          ),
        ),
      );
      return;
    }
    await context.read<AvailabilityController>().refresh(settings, only: kind);
  }

  Future<void> _saveKey() async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<SettingsController>().saveKey(
      _provider,
      _apiKey.text,
    );
    if (!mounted) return;
    if (success) _apiKey.clear();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Clé enregistrée dans le stockage sécurisé de l’appareil.'
              : 'Stockage sécurisé indisponible. La clé n’a pas été conservée en clair.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final availability = context.watch<AvailabilityController>();
    final busy = controller.busy || availability.busy;
    final cloudKind = _provider.engineKind;
    final cloudModelController = switch (_provider) {
      CloudProvider.openAi => _openAiModel,
      CloudProvider.anthropic => _anthropicModel,
      CloudProvider.groq => _groqModel,
    };
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 680 ? 20 : 36,
        4,
        MediaQuery.sizeOf(context).width < 680 ? 20 : 36,
        36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 830),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'MODE DE FONCTIONNEMENT',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.6,
                    color: OpenUsColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AiMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: AiMode.local,
                        icon: Icon(Icons.memory_rounded, size: 17),
                        label: Text('Local'),
                      ),
                      ButtonSegment(
                        value: AiMode.internet,
                        icon: Icon(Icons.cloud_outlined, size: 17),
                        label: Text('Internet'),
                      ),
                      ButtonSegment(
                        value: AiMode.automatic,
                        icon: Icon(Icons.auto_awesome_outlined, size: 17),
                        label: Text('Auto'),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: busy
                        ? null
                        : (value) => setState(() => _mode = value.first),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  switch (_mode) {
                    AiMode.local =>
                      'Utilise uniquement Ollama. Vos messages ne sont pas envoyés à un fournisseur Internet par OPENUS.',
                    AiMode.internet =>
                      'Utilise le fournisseur choisi. Vos messages lui sont transmis ; sa politique de confidentialité et sa facturation s’appliquent.',
                    AiMode.automatic =>
                      'Préfère Ollama lorsqu’un modèle est réellement disponible, sinon utilise le fournisseur Internet configuré.',
                  },
                  style: const TextStyle(
                    fontSize: 12,
                    color: OpenUsColors.muted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                NeonPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardTitle(
                        icon: Icons.memory_rounded,
                        title: 'IA locale',
                        trailing: _HealthBadge(kind: EngineKind.local),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ollama · connexion HTTP réelle · aucun modèle installé par OPENUS',
                        style: TextStyle(
                          fontSize: 12,
                          color: OpenUsColors.muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _endpoint,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Adresse du serveur Ollama',
                          hintText: 'http://127.0.0.1:11434',
                        ),
                        validator: (value) => AppSettings(
                          localEndpoint: value?.trim() ?? '',
                        ).endpointError,
                      ),
                      const SizedBox(height: 14),
                      _ModelField(
                        key: const ValueKey('local-model-field'),
                        controller: _localModel,
                        label: 'Modèle local installé',
                        models: availability[EngineKind.local].models,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: OpenUsColors.blue.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: OpenUsColors.blue.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profil léger · ${LocalModelProfile.displayName}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Poids publié : ${LocalModelProfile.publishedArtifactLabel}. '
                              'Cible : moins de 4 Gio pour Ollama avec ce profil, à mesurer sur votre appareil. '
                              'Ce n’est pas une limite de RAM totale pour Windows ou Android.',
                              style: TextStyle(
                                fontSize: 11,
                                color: OpenUsColors.muted,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const SelectableText(
                              LocalModelProfile.pullCommand,
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  key: const ValueKey('local-light-preset'),
                                  onPressed: busy ? null : _applyLightPreset,
                                  icon: const Icon(Icons.speed_rounded, size: 17),
                                  label: const Text('Choisir ce profil'),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    await Clipboard.setData(
                                      const ClipboardData(
                                        text: LocalModelProfile.pullCommand,
                                      ),
                                    );
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Commande copiée.'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  label: const Text('Copier la commande'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _lowMemory,
                        onChanged: busy
                            ? null
                            : (value) => setState(() => _lowMemory = value),
                        title: const Text(
                          'Profil faible mémoire',
                          style: TextStyle(fontSize: 13),
                        ),
                        subtitle: const Text(
                          'Contexte 2048, batch 128, réponse 512 tokens ; déchargement après réponse. '
                          'Connues au-delà de 2 Gio, les poids sont refusés. Ce garde-fou ne mesure pas la RAM.',
                          style: TextStyle(fontSize: 11, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        availability[EngineKind.local].message,
                        style: const TextStyle(
                          fontSize: 11,
                          color: OpenUsColors.muted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => _test(EngineKind.local),
                        icon: const Icon(
                          Icons.wifi_tethering_rounded,
                          size: 18,
                        ),
                        label: const Text('Vérifier et lister les modèles'),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Sur Android, 127.0.0.1 désigne le téléphone, pas votre PC. Utilisez l’adresse LAN du serveur, ou 10.0.2.2 pour un émulateur. HTTP distant est refusé ; HTTPS est recommandé hors loopback.',
                        style: TextStyle(
                          fontSize: 11,
                          color: OpenUsColors.muted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                NeonPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardTitle(
                        icon: Icons.cloud_outlined,
                        title: 'IA Internet',
                        trailing: _HealthBadge(kind: cloudKind),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final provider in CloudProvider.values)
                            ChoiceChip(
                              key: ValueKey('provider-${provider.name}'),
                              label: Text(provider.displayName),
                              selected: _provider == provider,
                              showCheckmark: false,
                              onSelected: busy
                                  ? null
                                  : (_) => _selectProvider(provider),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _ModelField(
                        key: ValueKey('model-${_provider.name}'),
                        controller: cloudModelController,
                        label: 'Identifiant exact du modèle',
                        models: availability[cloudKind].models,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey('api-key-field'),
                        controller: _apiKey,
                        obscureText: !_showKey,
                        autocorrect: false,
                        enableSuggestions: false,
                        maxLength: 512,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Clé API ${_provider.displayName}',
                          hintText: controller.hasKey(_provider)
                              ? 'Clé enregistrée · saisir pour remplacer'
                              : 'Collez votre propre clé API',
                          prefixIcon: const Icon(Icons.key_rounded, size: 19),
                          suffixIcon: IconButton(
                            tooltip: _showKey
                                ? 'Masquer la clé'
                                : 'Afficher la clé',
                            onPressed: () =>
                                setState(() => _showKey = !_showKey),
                            icon: Icon(
                              _showKey
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          ListenableBuilder(
                            listenable: _apiKey,
                            builder: (_, _) => OutlinedButton.icon(
                              key: const ValueKey('save-api-key'),
                              onPressed: busy || _apiKey.text.trim().isEmpty
                                  ? null
                                  : _saveKey,
                              icon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 17,
                              ),
                              label: const Text('Enregistrer la clé'),
                            ),
                          ),
                          if (controller.hasKey(_provider))
                            TextButton.icon(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final success = await controller
                                          .deleteKey(_provider);
                                      if (!mounted || !success) return;
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Clé supprimée du stockage sécurisé.',
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.delete_outline, size: 17),
                              label: const Text('Supprimer la clé'),
                            ),
                        ],
                      ),
                      if (_provider == CloudProvider.groq) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Créez votre clé personnelle sur console.groq.com/keys, puis collez-la ici. '
                          'Ne la partagez pas dans le chat ou GitHub. L’accès, les quotas et la facturation dépendent de votre compte Groq.',
                          style: TextStyle(
                            fontSize: 11,
                            color: OpenUsColors.muted,
                            height: 1.6,
                          ),
                        ),
                        const SelectableText(
                          'https://console.groq.com/keys',
                          style: TextStyle(fontSize: 11, color: OpenUsColors.blue),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        controller.hasKey(_provider)
                            ? 'Une clé est enregistrée sur cet appareil. Sa validité n’est pas présumée.'
                            : 'Aucune clé enregistrée pour ce fournisseur.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: OpenUsColors.muted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => _test(cloudKind),
                        icon: const Icon(
                          Icons.wifi_tethering_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Vérifier l’API et lister les modèles',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        availability[cloudKind].message,
                        style: const TextStyle(
                          fontSize: 11,
                          color: OpenUsColors.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Les clés ne sont jamais stockées avec les conversations. Les modèles affichés proviennent de l’API et peuvent inclure des modèles non conversationnels.',
                        style: TextStyle(
                          fontSize: 11,
                          color: OpenUsColors.muted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                NeonPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text(
                      'Instructions et contexte',
                      style: TextStyle(fontSize: 14),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _prompt,
                              minLines: 3,
                              maxLines: 6,
                              maxLength: 4000,
                              decoration: const InputDecoration(
                                labelText:
                                    'Instructions générales de l’assistant',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Contexte envoyé : $_contextMessages derniers messages',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Slider(
                              value: _contextMessages.toDouble(),
                              min: 4,
                              max: 40,
                              divisions: 18,
                              label: '$_contextMessages',
                              onChanged: (value) => setState(
                                () => _contextMessages = value.round(),
                              ),
                            ),
                            const Text(
                              'Il s’agit du contexte de la conversation active, pas d’une mémoire personnelle à long terme.',
                              style: TextStyle(
                                fontSize: 11,
                                color: OpenUsColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: busy ? null : _save,
                  icon: const Icon(Icons.check_rounded, size: 19),
                  label: const Text('Enregistrer la configuration'),
                ),
                const SizedBox(height: 24),
                const NoticeBanner(
                  message:
                      'Ollama et les poids ne sont pas inclus dans OPENUS : installation séparée. llama.cpp / GGUF embarqué reste à développer. Les commandes système, les outils et les actions autonomes ne sont pas implémentés.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.title,
    required this.trailing,
  });
  final IconData icon;
  final String title;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      trailing,
    ],
  );
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.kind});
  final EngineKind kind;
  @override
  Widget build(BuildContext context) {
    final health = context.watch<AvailabilityController>()[kind];
    final (label, color) = switch (health.state) {
      HealthState.available => ('Vérifié', OpenUsColors.success),
      HealthState.unavailable => ('Indisponible', OpenUsColors.danger),
      HealthState.checking => ('Vérification…', OpenUsColors.blue),
      HealthState.notConfigured => ('Non configuré', OpenUsColors.muted),
      HealthState.unknown => ('Non vérifié', OpenUsColors.warning),
    };
    return Tooltip(
      message: health.message,
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}

class _ModelField extends StatelessWidget {
  const _ModelField({
    super.key,
    required this.controller,
    required this.label,
    required this.models,
  });
  final TextEditingController controller;
  final String label;
  final List<String> models;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    autocorrect: false,
    maxLength: 200,
    decoration: InputDecoration(
      labelText: label,
      hintText: 'Nom exact fourni par le moteur',
      counterText: '',
      suffixIcon: PopupMenuButton<String>(
        tooltip: models.isEmpty
            ? 'Vérifiez le moteur pour découvrir ses modèles'
            : 'Choisir un modèle détecté',
        enabled: models.isNotEmpty,
        onSelected: (value) => controller.text = value,
        itemBuilder: (_) => [
          for (final model in models.take(150))
            PopupMenuItem(
              value: model,
              child: Text(model, style: const TextStyle(fontSize: 12)),
            ),
        ],
        icon: const Icon(Icons.arrow_drop_down_rounded),
      ),
    ),
    validator: (value) =>
        (value?.trim().length ?? 0) > 200 ? 'Nom de modèle trop long.' : null,
  );
}
