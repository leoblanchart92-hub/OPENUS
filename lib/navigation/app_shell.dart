import 'package:flutter/material.dart';

import '../companion/companion_controller.dart';
import '../companion/floating_companion_overlay.dart';
import '../core/responsive/responsive_layout.dart';
import '../core/theme/nexus_colors.dart';
import '../screens/compact_companion_screen.dart';
import '../screens/companion_screen.dart';
import '../screens/conversations_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../services/chat_service.dart';
import '../services/desktop_window_service.dart';
import '../settings/settings_controller.dart';
import '../widgets/nexus_badge.dart';
import '../widgets/window_control_bar.dart';
import 'desktop_sidebar.dart';
import 'mobile_bottom_nav.dart';
import 'nexus_destination.dart';

/// Root responsive shell adapting automatically across Windows desktop,
/// tablets, Android phones, and iPhones.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.companionController,
    required this.settingsController,
    required this.chatService,
    required this.desktopWindowService,
  });

  final CompanionController companionController;
  final SettingsController settingsController;
  final ChatService chatService;
  final DesktopWindowService desktopWindowService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  NexusDestination _destination = NexusDestination.home;

  void _selectDestination(NexusDestination dest) {
    if (_destination == dest) {
      return;
    }
    setState(() => _destination = dest);
  }

  void _startNewConversationAndOpen() {
    widget.chatService.createNewConversation();
    setState(() => _destination = NexusDestination.conversations);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.desktopWindowService,
        widget.settingsController,
      ]),
      builder: (context, _) {
        if (widget.desktopWindowService.isCompactView) {
          return CompactCompanionScreen(
            companionController: widget.companionController,
            chatService: widget.chatService,
            desktopWindowService: widget.desktopWindowService,
            onExpandToChat: () =>
                _selectDestination(NexusDestination.conversations),
          );
        }

        final screenClass = ResponsiveLayout.of(context);
        final useSidebar = screenClass == NexusScreenClass.desktop ||
            screenClass == NexusScreenClass.tablet;
        final isCompactRail = screenClass == NexusScreenClass.tablet;
        final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 90;

        final showFloatingOverlay = widget
                .settingsController.settings.showInAppFloatingCompanion &&
            _destination != NexusDestination.conversations &&
            _destination != NexusDestination.companion &&
            !keyboardVisible;

        final pageContent = IndexedStack(
          index: _destination.index,
          children: [
            HomeScreen(
              companionController: widget.companionController,
              chatService: widget.chatService,
              settingsController: widget.settingsController,
              desktopWindowService: widget.desktopWindowService,
              onOpenConversations: () =>
                  _selectDestination(NexusDestination.conversations),
              onOpenCompanionStudio: () =>
                  _selectDestination(NexusDestination.companion),
              onOpenSettings: () =>
                  _selectDestination(NexusDestination.settings),
            ),
            ConversationsScreen(
              chatService: widget.chatService,
              companionController: widget.companionController,
              desktopWindowService: widget.desktopWindowService,
            ),
            HistoryScreen(
              chatService: widget.chatService,
              onOpenConversation: () =>
                  _selectDestination(NexusDestination.conversations),
            ),
            CompanionScreen(
              companionController: widget.companionController,
              settingsController: widget.settingsController,
              desktopWindowService: widget.desktopWindowService,
            ),
            SettingsScreen(
              settingsController: widget.settingsController,
              chatService: widget.chatService,
              desktopWindowService: widget.desktopWindowService,
            ),
          ].asMap().entries.map((entry) {
            return TickerMode(
              enabled: entry.key == _destination.index,
              child: entry.value,
            );
          }).toList(growable: false),
        );

        final decoratedBackground = DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.65, -0.75),
              radius: 1.35,
              colors: [
                Color(0xFF161030),
                NexusColors.voidBlack,
              ],
            ),
          ),
          child: pageContent,
        );

        if (useSidebar) {
          return Scaffold(
            backgroundColor: NexusColors.voidBlack,
            body: Stack(
              children: [
                Row(
                  children: [
                    DesktopSidebar(
                      selected: _destination,
                      onSelect: _selectDestination,
                      onNewConversation: _startNewConversationAndOpen,
                      companionController: widget.companionController,
                      desktopWindowService: widget.desktopWindowService,
                      compactRail: isCompactRail,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          WindowControlBar(
                            title: _destination.label,
                            desktopWindowService: widget.desktopWindowService,
                          ),
                          Expanded(child: decoratedBackground),
                        ],
                      ),
                    ),
                  ],
                ),
                if (showFloatingOverlay)
                  FloatingCompanionOverlay(
                    controller: widget.companionController,
                    onOpenCompanionStudio: () =>
                        _selectDestination(NexusDestination.companion),
                    onOpenCompactMode:
                        widget.desktopWindowService.toggleCompactView,
                  ),
              ],
            ),
          );
        }

        // Mobile portrait/landscape layout (Android & iOS)
        return Scaffold(
          backgroundColor: NexusColors.voidBlack,
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: NexusColors.obsidian.alphaFactor(0.92),
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NexusColors.electricViolet,
                    boxShadow: [
                      BoxShadow(
                        color: NexusColors.electricViolet.alphaFactor(0.8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Nexus AI • ${_destination.label}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: NexusBadge(label: 'Démo'),
              ),
              IconButton(
                key: const ValueKey<String>('mobile_compact_button'),
                tooltip: 'Aperçu Compagnon compact',
                onPressed: widget.desktopWindowService.toggleCompactView,
                icon: const Icon(
                  Icons.picture_in_picture_alt_rounded,
                  size: 20,
                  color: NexusColors.lavenderGlow,
                ),
              ),
              const SizedBox(width: 4),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            ),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(child: decoratedBackground),
                  if (!keyboardVisible)
                    MobileBottomNav(
                      selected: _destination,
                      onSelect: _selectDestination,
                    ),
                ],
              ),
              if (showFloatingOverlay)
                FloatingCompanionOverlay(
                  controller: widget.companionController,
                  minBottomInset: 88,
                  onOpenCompanionStudio: () =>
                      _selectDestination(NexusDestination.companion),
                  onOpenCompactMode:
                      widget.desktopWindowService.toggleCompactView,
                ),
            ],
          ),
        );
      },
    );
  }
}
