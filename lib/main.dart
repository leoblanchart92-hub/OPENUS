import 'package:flutter/material.dart';

import 'app.dart';
import 'services/update_checkpoint.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await UpdateCheckpoint.load();
    runApp(const NexusAiApp());
  } catch (_) {
    // Do not overwrite unreadable user data with demo defaults.
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text(
      'Les données sauvegardées ne peuvent pas être lues. '
      'Elles ont été conservées. Contactez le support avant de continuer.',
    )))));
  }
}
