import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/openus_theme.dart';
import '../../state/settings_controller.dart';
import '../widgets/neon_panel.dart';
import 'settings/engine_settings_page.dart';
import 'settings/voice_settings_page.dart';
import 'settings/appearance_settings_page.dart';
import 'settings/about_settings_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    final notice = context.watch<SettingsController>().notice;
    return DefaultTabController(length: 4, child: Column(children: [
      Padding(padding: EdgeInsets.fromLTRB(compact ? 20 : 36, compact ? 20 : 30, compact ? 20 : 36, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeading('CONFIGURATION', 'À votre façon.', description: 'Choisissez vos moteurs, votre voix et votre expérience.',
            trailing: IconButton(tooltip: 'Retour à l’assistant', onPressed: onBack, icon: const Icon(Icons.close_rounded))),
          if (notice != null) NoticeBanner(message: notice, warning: true,
            action: IconButton(tooltip: 'Fermer le message', onPressed: context.read<SettingsController>().clearNotice, icon: const Icon(Icons.close, size: 16))),
          const Align(alignment: Alignment.centerLeft, child: TabBar(isScrollable: true, tabAlignment: TabAlignment.start,
            labelColor: OpenUsColors.text, unselectedLabelColor: OpenUsColors.muted,
    dividerColor: OpenUsColors.border, indicatorSize: TabBarIndicatorSize.label,
            tabs: [Tab(text: 'Moteurs IA'), Tab(text: 'Voix'), Tab(text: 'Apparence'), Tab(text: 'À propos')])),
        ])),
      const Expanded(child: TabBarView(children: [
        EngineSettingsPage(), VoiceSettingsPage(), AppearanceSettingsPage(), AboutSettingsPage(),
      ])),
    ]));
  }
}
