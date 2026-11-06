# Dépendances et compatibilité

Vérification documentaire effectuée le 2026-11-06. Les contraintes sont dans `pubspec.yaml` et les versions résolues sont verrouillées dans `pubspec.lock`. `flutter pub get` est exécuté par la CI avec Flutter 3.44.9 ; les versions transitive exactes sont celles du journal de résolution de cette exécution. Le lockfile est généré par la CI puis versionné sur la branche de session ; il n’a pas été résolu localement dans le sandbox.

| paquet | contrainte | usage | Android | Windows |
|---|---|---|---|---|
| provider | ^6.1.5 | injection et état | Dart pur | Dart pur |
| http | ^1.6.0 | APIs IA et annulation | oui | oui |
| shared_preferences | ^2.5.6 | préférences non sensibles | oui | oui |
| flutter_secure_storage | ^10.3.4 | clés API | Keystore / chiffrements personnalisés v10 | AES-GCM + Credential Manager, ATL requis |
| path_provider | ^2.1.5 | répertoire privé | oui | oui |
| speech_to_text | ^7.3.0 | dictée native | oui | oui, expérimental |
| flutter_tts | ^4.2.5 | synthèse native | oui | oui |
| flutter_lints | ^6.0.0 | analyse statique | développement | développement |

## Sources consultées

- Flutter SDK et templates natifs : https://github.com/flutter/flutter/tree/3.44.9
- Provider : https://pub.dev/packages/provider
- HTTP : https://pub.dev/packages/http
- Préférences : https://pub.dev/packages/shared_preferences
- Stockage sécurisé : https://github.com/juliansteenbakker/flutter_secure_storage/tree/v10.3.4
- Reconnaissance : https://pub.dev/packages/speech_to_text et https://github.com/csdcorp/speech_to_text/tree/v7.3.0
- Synthèse : https://pub.dev/packages/flutter_tts et https://github.com/dlutton/flutter_tts
- Chemins applicatifs : https://pub.dev/packages/path_provider
- Ollama API : https://github.com/ollama/ollama/blob/main/docs/api.md
- OpenAI Chat Completions : https://platform.openai.com/docs/api-reference/chat
- Anthropic Messages : https://docs.anthropic.com/en/api/messages

## Points d’attention

- `speech_to_text` 7.3 introduit le support Windows encore décrit comme expérimental par son éditeur. Une compilation ne garantit pas la disponibilité du service vocal sur chaque machine.
- `flutter_secure_storage` 10.3.4 nécessite les bibliothèques C++ ATL avec Visual Studio Build Tools. Son implémentation Windows récente chiffre les valeurs dans des fichiers et protège la clé via Credential Manager ; ce n’est pas simplement « une valeur dans le registre ».
- Android doit déclarer `INTERNET`, `RECORD_AUDIO` et la visibilité du service `android.speech.RecognitionService`. Le microphone est une fonctionnalité optionnelle (`required=false`).
- Le cleartext Android est autorisé pour les origines LAN locales. Le validateur d’origine refuse HTTP public et les URLs contenant identifiants, requête ou fragment. Ce n’est pas un pare-feu natif complet : une politique réseau plus stricte est recommandée avant publication.
- Aucun paquet de réveil vocal, FFI llama.cpp, base vectorielle, WebView ou automation système n’a été ajouté prématurément.
- Les bibliothèques natives sont récupérées par Flutter/Gradle/NuGet sur le poste de compilation ou la CI, jamais sur une clé USB par OPENUS.

## Versions natives de référence

Les fichiers Android proviennent du template Flutter 3.44.9 : Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20, Java 17, compile/target SDK 36 et min SDK 24 via les valeurs Flutter. Le wrapper Gradle officiel est versionné. Le runner Windows utilise CMake et C++17 ; la CI vérifie la compilation sur windows-latest.
