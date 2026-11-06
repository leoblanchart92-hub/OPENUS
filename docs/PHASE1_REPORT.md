# OPENUS — Compte rendu de phase 1

## Périmètre livré

Base Flutter/Dart créée directement dans le dépôt, avec runners Android et Windows, architecture modulaire, interface responsive et documentation en français. Le dépôt initial ne contenait que `README.md` et aucun logo.

### Fichiers et dossiers créés

- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.gitignore` ;
- `lib/main.dart`, `lib/app.dart` et les modules `core`, `domain`, `data`, `services`, `state`, `ui` ;
- `android/` : configuration Gradle Kotlin DSL, manifest, activité, ressources, wrapper officiel et signature release optionnelle ;
- `windows/` : runner Win32/CMake, ressources et nom binaire OPENUS ;
- `assets/branding/` : emplacement du logo officiel ;
- `test/` : tests de domaine, adaptateurs, stockage, conversations et widgets ; doublures de test uniquement ;
- `.github/workflows/ci.yml` et `.github/scripts/report_log.py` ;
- `README.md` réécrit et documents `docs/ARCHITECTURE.md`, `docs/DEPENDENCIES.md`, `docs/BUILD_ANDROID.md`, `docs/BUILD_WINDOWS.md`, `docs/VERIFICATION.md`, ce rapport.

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

Le sandbox local ne pouvait pas démarrer Flutter complètement, car le téléchargement du Dart SDK depuis `storage.googleapis.com` est hors de la liste réseau autorisée. Les commandes Flutter locales n’y ont donc pas été présentées comme réussies.

La CI GitHub a été exécutée réellement sur le commit de code `f8aa53027ff1032a45a4e09c80a07f869f5b90be` :

- `flutter pub get` : réussi ;
- contrôle du formatage Dart : réussi ;
- `flutter analyze` : réussi, aucun problème remonté ;
- `flutter test` : réussi, suite de 24 tests unitaires/widgets ;
- `flutter build apk --debug` : réussi, artefact Android debug produit ;
- `flutter build windows --release` : réussi, artefact Windows produit.

Exécution de référence : https://github.com/leoblanchart92-hub/OPENUS/actions/runs/42167577745
Détail : [docs/VERIFICATION.md](VERIFICATION.md).

Aucun moteur IA réel, compte API payant, microphone, appareil Android physique ou lancement runtime Windows utilisateur n’a été testé fonctionnellement dans le sandbox. Les artefacts CI sont des builds de validation, pas des distributions signées.

## Prochaine action utilisateur

Suivre `docs/BUILD_ANDROID.md` pour générer un premier APK debug, puis configurer Ollama ou un fournisseur personnel. Le logo officiel pourra être déposé dans `assets/branding/openus_logo.png` sans modification de l’architecture.
