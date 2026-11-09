import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai/ai_provider.dart';
import 'ai/demo_ai_service.dart';
import 'companion/companion_controller.dart';
import 'core/theme/nexus_colors.dart';
import 'core/theme/nexus_theme.dart';
import 'navigation/app_shell.dart';
import 'services/chat_service.dart';
import 'services/desktop_window_service.dart';
import 'settings/settings_controller.dart';
import 'widgets/desktop_window_feedback.dart';

class NexusAiApp extends StatefulWidget {
  const NexusAiApp({
    super.key,
    this.aiProvider,
    this.speakingShowcaseDuration = const Duration(milliseconds: 1200),
  });

  final AiProviderService? aiProvider;
  final Duration speakingShowcaseDuration;

  @override
  State<NexusAiApp> createState() => _NexusAiAppState();
}

class _NexusAiAppState extends State<NexusAiApp> {
  late final CompanionController _companionController;
  late final SettingsController _settingsController;
  late final ChatService _chatService;
  late final DesktopWindowService _desktopWindowService;

  @override
  void initState() {
    super.initState();
    _companionController = CompanionController();
    _settingsController = SettingsController(
      companionController: _companionController,
    );
    _chatService = ChatService(
      aiProvider: widget.aiProvider ?? DemoAiService(),
      companionController: _companionController,
      settingsController: _settingsController,
      speakingShowcaseDuration: widget.speakingShowcaseDuration,
    );
    _desktopWindowService = DesktopWindowService()..initialize();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: NexusColors.obsidian,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _chatService.dispose();
    _settingsController.dispose();
    _companionController.dispose();
    _desktopWindowService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus AI',
      debugShowCheckedModeBanner: false,
      theme: NexusTheme.buildDarkTheme(),
      home: DesktopWindowFeedback(
        service: _desktopWindowService,
        child: AppShell(
          companionController: _companionController,
          settingsController: _settingsController,
          chatService: _chatService,
          desktopWindowService: _desktopWindowService,
        ),
      ),
    );
  }
}
