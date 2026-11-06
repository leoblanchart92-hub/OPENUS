import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/http_json_client.dart';
import 'core/theme/openus_theme.dart';
import 'data/conversation_repository.dart';
import 'data/credential_store.dart';
import 'data/settings_repository.dart';
import 'domain/app_settings.dart';
import 'services/ai/engine_router.dart';
import 'services/voice/voice_controller.dart';
import 'state/availability_controller.dart';
import 'state/conversation_controller.dart';
import 'state/settings_controller.dart';
import 'ui/screens/home_shell.dart';
import 'ui/widgets/brand_mark.dart';

/// Composition root: native storage and adapters are injected into the UI layer.
class OpenUsBootstrap extends StatefulWidget {
  const OpenUsBootstrap({super.key});
  @override
  State<OpenUsBootstrap> createState() => _OpenUsBootstrapState();
}

class _Services {
  _Services(this.settings, this.availability, this.conversations, this.voice);
  final SettingsController settings;
  final AvailabilityController availability;
  final ConversationController conversations;
  final VoiceController voice;
  VoidCallback? voiceSync;
  void dispose() {
    if (voiceSync != null) settings.removeListener(voiceSync!);
    voice.dispose();
    conversations.dispose();
    availability.dispose();
    settings.dispose();
  }
}

class _OpenUsBootstrapState extends State<OpenUsBootstrap> {
  _Services? _services;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _Services? services;
    try {
      final preferences = await SharedPreferences.getInstance();
      final directory = await getApplicationSupportDirectory();
      final repository = SettingsRepository(preferences);
      final loaded = repository.load();
      final credentials = SecureCredentialStore();
      final settings = SettingsController(
        repository: repository,
        credentials: credentials,
        initial: loaded.settings,
        warning: loaded.warning,
      );
      final conversationRepository = JsonConversationRepository(directory);
      late AvailabilityController availability;
      final router = EngineRouter(
        credentials: credentials,
        http: HttpJsonClient(http.Client.new),
        onProbe: availability.record,
      );
      availability = AvailabilityController(router, credentials);
      final conversations = ConversationController(
        repository: conversationRepository,
        router: router,
        settings: () => settings.settings,
        onEngineSuccess: availability.noteSuccess,
      );
      final voice = VoiceController()..configure(settings.settings);
      services = _Services(settings, availability, conversations, voice);
      services.voiceSync = () => voice.configure(settings.settings);
      settings.addListener(services.voiceSync!);
      await Future.wait([settings.initialize(), conversations.initialize()]);
      if (!mounted) {
        services.dispose();
        return;
      }
      setState(() {
        _services = services;
        _loading = false;
      });
    } catch (_) {
      services?.dispose();
      if (mounted)
        setState(() {
          _loading = false;
          _error =
              'OPENUS ne peut pas ouvrir le stockage de cet appareil. Vérifiez les permissions et l’espace disponible, puis réessayez.';
        });
    }
  }

  @override
  void dispose() {
    _services?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    if (services == null)
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OPENUS',
        theme: OpenUsTheme.build(const AppSettings()),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLockup(),
                    const SizedBox(height: 40),
                    if (_loading)
                      const CircularProgressIndicator()
                    else
                      const Icon(
                        Icons.storage_outlined,
                        size: 40,
                        color: OpenUsColors.warning,
                      ),
                    const SizedBox(height: 24),
                    Text(
                      _error ?? 'Ouverture de votre espace local…',
                      textAlign: TextAlign.center,
                    ),
                    if (!_loading) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _start,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: services.settings),
        ChangeNotifierProvider.value(value: services.availability),
        ChangeNotifierProvider.value(value: services.conversations),
        ChangeNotifierProvider.value(value: services.voice),
      ],
      child: const OpenUsApp(),
    );
  }
}

class OpenUsApp extends StatelessWidget {
  const OpenUsApp({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    return MaterialApp(
      title: 'OPENUS — Your personal AI',
      debugShowCheckedModeBanner: false,
      theme: OpenUsTheme.build(settings),
      darkTheme: OpenUsTheme.build(settings),
      themeMode: ThemeMode.dark,
      home: const HomeShell(),
    );
  }
}
