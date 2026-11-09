import 'dart:convert';
import 'dart:io';

import '../companion/companion_state.dart';
import '../core/models/chat_message.dart';
import '../core/models/conversation.dart';
import '../settings/app_settings.dart';

/// Upgrade checkpoint outside the installation directory. Never uninstalled.
class UpdateCheckpoint {
  static UpdateCheckpoint? restored;
  const UpdateCheckpoint(this.settings, this.conversations);
  final AppSettings settings;
  final List<Conversation> conversations;

  static File get _file {
    final root = Platform.environment['LOCALAPPDATA'];
    if (root == null || root.isEmpty) {
      throw StateError('LOCALAPPDATA unavailable');
    }
    return File('$root/NexusAI/user-state.json');
  }

  static Future<void> load({File? storage}) async {
    if (storage == null && !Platform.isWindows) {
      return;
    }
    final file = storage ?? _file;
    final backup = File('${file.path}.previous');
    final source = await file.exists() ? file : backup;
    if (!await source.exists()) {
      return;
    }
    final json = jsonDecode(await source.readAsString()) as Map<String, dynamic>;
    if (json['schema'] != 1) {
      throw const FormatException('Unknown state schema');
    }
    final s = json['settings'] as Map<String, dynamic>;
    restored = UpdateCheckpoint(AppSettings(
      showInAppFloatingCompanion: s['floating'] as bool,
      showOrbitalAura: s['orbital'] as bool,
      glowIntensity: (s['glow'] as num).toDouble(),
      reducedMotion: s['reduced'] as bool,
      paletteId: CompanionPaletteId.values.byName(s['palette'] as String),
      preferredGroqModelId: s['model'] as String,
    ), (json['conversations'] as List<dynamic>).map((dynamic item) {
      final c = item as Map<String, dynamic>;
      return Conversation(id: c['id'] as String, title: c['title'] as String,
        updatedAt: DateTime.parse(c['updated'] as String),
        isDemo: c['demo'] as bool, topicTag: c['topic'] as String,
        messages: (c['messages'] as List<dynamic>).map((dynamic item) {
          final m = item as Map<String, dynamic>;
          return ChatMessage(id: m['id'] as String,
            sender: MessageSender.values.byName(m['sender'] as String),
            content: m['content'] as String,
            timestamp: DateTime.parse(m['timestamp'] as String),
            isDemo: m['demo'] as bool, providerLabel: m['provider'] as String);
        }).toList());
    }).toList());
  }

  Future<void> save({File? storage}) async {
    final file = storage ?? _file;
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.pending');
    await temp.writeAsString(jsonEncode({
      'schema': 1,
      'settings': {
        'floating': settings.showInAppFloatingCompanion,
        'orbital': settings.showOrbitalAura, 'glow': settings.glowIntensity,
        'reduced': settings.reducedMotion, 'palette': settings.paletteId.name,
        'model': settings.preferredGroqModelId,
      },
      'conversations': conversations.map((c) => {
        'id': c.id, 'title': c.title, 'updated': c.updatedAt.toIso8601String(),
        'demo': c.isDemo, 'topic': c.topicTag,
        'messages': c.messages.map((m) => {
          'id': m.id, 'sender': m.sender.name, 'content': m.content,
          'timestamp': m.timestamp.toIso8601String(), 'demo': m.isDemo,
          'provider': m.providerLabel,
        }).toList(),
      }).toList(),
    }), flush: true);
    final backup = File('${file.path}.previous');
    if (await file.exists()) {
      if (await backup.exists()) {
        await backup.delete();
      }
      await file.rename(backup.path);
    }
    await temp.rename(file.path);
  }
}
