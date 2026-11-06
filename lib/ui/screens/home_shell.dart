import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_info.dart';
import '../../core/theme/openus_theme.dart';
import '../../state/conversation_controller.dart';
import '../widgets/brand_mark.dart';
import '../widgets/status_pill.dart';
import 'assistant_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

enum WorkspacePage { assistant, history, settings }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  WorkspacePage _page = WorkspacePage.assistant;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  void _navigate(WorkspacePage page) {
    setState(() => _page = page);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  void _newConversation() {
    context.read<ConversationController>().newConversation();
    _navigate(WorkspacePage.assistant);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 1080;
    final rail = width >= 680 && !desktop;
    final page = switch (_page) {
      WorkspacePage.assistant => AssistantScreen(
        onSettings: () => _navigate(WorkspacePage.settings),
      ),
      WorkspacePage.history => HistoryScreen(
        onOpen: () => _navigate(WorkspacePage.assistant),
        onNew: _newConversation,
      ),
      WorkspacePage.settings => SettingsScreen(
        onBack: () => _navigate(WorkspacePage.assistant),
      ),
    };
    return Scaffold(
      key: _scaffoldKey,
      appBar: desktop
          ? null
          : AppBar(
              title: const BrandLockup(compact: true),
              leading: rail
                  ? null
                  : IconButton(
                      tooltip: 'Ouvrir le menu',
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
              actions: [
                if (_page != WorkspacePage.settings)
                  IconButton(
                    tooltip: 'Paramètres',
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: () => _navigate(WorkspacePage.settings),
                  ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: OpenUsColors.border),
              ),
            ),
      drawer: desktop || rail
          ? null
          : Drawer(
              width: 280,
              backgroundColor: OpenUsColors.background,
              child: SafeArea(
                child: _Sidebar(
                  page: _page,
                  onNavigate: _navigate,
                  onNew: _newConversation,
                  showRecent: true,
                ),
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (desktop)
              SizedBox(
                width: 260,
                child: _Sidebar(
                  page: _page,
                  onNavigate: _navigate,
                  onNew: _newConversation,
                  showRecent: true,
                ),
              ),
            if (rail)
              NavigationRail(
                selectedIndex: _page.index,
                onDestinationSelected: (i) =>
                    _navigate(WorkspacePage.values[i]),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Column(
                    children: [
                      const BrandMark(size: 34),
                      const SizedBox(height: 24),
                      IconButton.filledTonal(
                        tooltip: 'Nouvelle conversation',
                        onPressed: _newConversation,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(Icons.auto_awesome),
                    label: Text('Assistant'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.history_rounded),
                    label: Text('Historique'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.tune_rounded),
                    label: Text('Paramètres'),
                  ),
                ],
              ),
            if (desktop || rail)
              Container(width: 1, color: OpenUsColors.border),
            Expanded(child: page),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.page,
    required this.onNavigate,
    required this.onNew,
    required this.showRecent,
  });
  final WorkspacePage page;
  final ValueChanged<WorkspacePage> onNavigate;
  final VoidCallback onNew;
  final bool showRecent;
  @override
  Widget build(BuildContext context) {
    final conversations = context
        .watch<ConversationController>()
        .conversations
        .where((c) => c.messages.isNotEmpty)
        .take(6)
        .toList();
    final active = context.select<ConversationController, String?>(
      (c) => c.active?.id,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(25, 28, 20, 34),
          child: BrandLockup(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: FilledButton.icon(
            onPressed: onNew,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Nouvelle conversation'),
          ),
        ),
        const SizedBox(height: 26),
        _NavItem(
          icon: Icons.auto_awesome_outlined,
          label: 'Assistant',
          selected: page == WorkspacePage.assistant,
          onTap: () => onNavigate(WorkspacePage.assistant),
        ),
        _NavItem(
          icon: Icons.history_rounded,
          label: 'Conversations',
          selected: page == WorkspacePage.history,
          onTap: () => onNavigate(WorkspacePage.history),
        ),
        _NavItem(
          icon: Icons.tune_rounded,
          label: 'Paramètres',
          selected: page == WorkspacePage.settings,
          onTap: () => onNavigate(WorkspacePage.settings),
        ),
        if (showRecent) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 30, 20, 12),
            child: Text(
              'RÉCENTES',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.8,
                color: OpenUsColors.muted,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (conversations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(13),
                    child: Text(
                      'Votre historique apparaîtra ici.',
                      style: TextStyle(color: OpenUsColors.muted, fontSize: 12),
                    ),
                  ),
                for (final conversation in conversations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      selected:
                          page == WorkspacePage.assistant &&
                          active == conversation.id,
                      selectedTileColor: OpenUsColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 15,
                        color: OpenUsColors.muted,
                      ),
                      title: Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        context.read<ConversationController>().select(
                          conversation.id,
                        );
                        onNavigate(WorkspacePage.assistant);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ] else
          const Spacer(),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EngineStatusPill(),
              SizedBox(height: 14),
              Text(
                '${AppInfo.phase}  ·  v${AppInfo.version}',
                style: TextStyle(color: OpenUsColors.muted, fontSize: 10),
              ),
              SizedBox(height: 5),
              Text(
                'Votre espace. Votre intelligence.',
                style: TextStyle(color: Color(0xFF626981), fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : OpenUsColors.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: ListTile(
        selected: selected,
        selectedTileColor: color.withValues(alpha: .08),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: color, size: 21),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? OpenUsColors.text : OpenUsColors.muted,
            fontSize: 13,
          ),
        ),
        trailing: selected
            ? Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : null,
      ),
    );
  }
}
