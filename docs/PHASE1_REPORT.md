# OPENUS — Compte rendu de phase 1

## Périmètre livré

Base Flutter/Dart créée directement dans le dépôt, avec runners Android et Windows, architecture modulaire, interface responsive et documentation en français. Le dépôt initial ne contenait que `README.md` et aucun logo.

### Fichiers et dossiers créés

- `pubspec.yaml`, `analysis_options.yaml`, `.gitignore` ;
- `lib/main.dart`, `lib/app.dart` et les modules `core`, `domain`, `data`, `services`, `state`, `ui` ;
- `android/` : configuration Gradle Kotlin DSL, manifest, activité, ressources, wrapper officiel et signature release optionnelle ;
- `windows/` : runner Win32/CMake, ressources et nom binaire OPENUS ;
- `assets/branding/` : emplacement du logo officiel ;
- `test/` : tests de domaine, adaptateurs, stockage, conversations et widgets ; doublures de test uniquement ;
- `.github/workflows/ci.yml` ;
- `README.md` réécrit et documents `docs/ARCHITECTURE.md`, `docs/DEPENDENCIES.md`, `docs/BUILD_ANDROID.md`, `docs/BUILD_WINDOWS.md`, ce rapport.

Le détail exact est disponible dans le diff Git de la branche de session. Aucun fichier utile préexistant n’a été supprimé.

### Fonctionnalités implémentées dans le code

- Accueil, conversation, compositeur, envoi, micro, animation centrale, état de configuration/disponibilité, paramètres et historique.
- Thème sombre, accents violet/bleu, halos désactivables, réduction des animations, navigation mobile/intermédiaire/desktop.
- Conversations persistantes, recherche, création, sélection, suppression et effacement confirmé.
- Contexte borné par conversation ; pas de mémoire à long terme simulée.
- Contrats IA et adaptateurs HTTP Ollama/OpenAI/Anthropic ; modes local/Internet/auto ; vérification réelle et annulation.
- Paramètres persistants et clés dans un stockage sécurisé séparé.
- Dictée et synthèse natives conditionnées par l’appareil ; aucun envoi vocal automatique.
- États d’erreur explicites, absence de fausses réponses et de fausses clés.

### Reste à développer

llama.cpp/GGUF embarqué, gestion/téléchargement de modèles locaux, streaming, rendu Markdown, mémoire sémantique, outils et actions système, mot de réveil, choix avancé des voix, installateur/signature Windows, signature release et distribution Android, chiffrement/migrations/pagination de grands historiques, tests matériels et tests d’intégration de vrais comptes.

## Vérifications

Le sandbox ne fournit pas initialement Flutter/Dart/JDK/Android SDK. Le SDK Flutter 3.44.9 a été récupéré depuis GitHub dans un dossier outil hors dépôt, mais son démarrage télécharge le Dart SDK depuis `storage.googleapis.com`, domaine non autorisé dans cet environnement. Les commandes Flutter locales ne peuvent donc pas être présentées comme réussies ici.

La CI GitHub a été mise en place pour exécuter réellement `flutter pub get`, le formatage, `flutter analyze`, `flutter test`, `flutter build apk --debug` et `flutter build windows --release`. Les résultats observés sont consignés dans `docs/VERIFICATION.md` après exécution ; ce fichier est la source de vérité du statut de validation.

Aucune compilation réussie n’est affirmée sur la seule base de la structure des fichiers. Aucun moteur IA réel, compte API payant, microphone ou appareil Android n’est disponible pour les essais fonctionnels dans le sandbox.

## Prochaine action utilisateur

Suivre `docs/BUILD_ANDROID.md` pour générer un premier APK debug, puis configurer Ollama ou un fournisseur personnel. Le logo officiel pourra être déposé dans `assets/branding/openus_logo.png` sans modification de l’architecture.
