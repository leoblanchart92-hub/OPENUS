# OPENUS

**YOUR PERSONAL AI**

Assistant personnel modulaire en **Flutter / Dart**, conçu pour **Android** et **Windows 10/11**. Cette base applicative comprend : interface responsive, conversations persistantes, paramètres, stockage sécurisé des clés et connecteurs IA réels optionnels.

> OPENUS ne contient ni modèle IA embarqué, ni clé API préinstallée, ni réponse simulée. Sans moteur configuré, l’application affiche explicitement cet état et conserve l’erreur de la requête.

## Démarrage

Le SDK de référence est **Flutter 3.44.9 stable**. Le projet déclare un minimum Flutter 3.44 / Dart 3.12 ; utilisez de préférence la version de la CI pour reproduire les vérifications.

```bash
flutter --version
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run
```

Le dépôt était vide hormis son README initial. Les squelettes Android et Windows sont maintenant versionnés. Il n’est pas nécessaire de recréer le projet par-dessus ces fichiers.

### Premier APK Android

Prérequis : Flutter, Android SDK/platform/build-tools correspondants, JDK 17 et un appareil Android compatible (API 24 minimum avec le SDK de référence). Acceptez les licences Android sur votre poste de développement.

```bash
flutter doctor -v
flutter pub get
flutter build apk --debug
```

Sortie : `build/app/outputs/flutter-apk/app-debug.apk`.

Cet APK de développement est signé avec l’identité debug locale. Il est destiné aux essais, pas à une publication. La procédure de signature release est décrite dans [docs/BUILD_ANDROID.md](docs/BUILD_ANDROID.md). Aucun mot de passe ou keystore n’est inclus dans le dépôt.

### Windows

Sur Windows, installez Visual Studio 2022 avec **Desktop development with C++**, les composants **C++ ATL**, et le SDK Windows. Les composants ATL sont nécessaires au stockage sécurisé.

```powershell
flutter config --enable-windows-desktop
flutter pub get
flutter build windows --release
```

Le résultat est un **dossier autonome contenant OPENUS.exe et ses DLL/ressources**, pas un EXE unique. L’installateur, la signature et la distribution Windows constituent une phase ultérieure. Voir [docs/BUILD_WINDOWS.md](docs/BUILD_WINDOWS.md).

## Ce qui est intégré

- Interface noire, violet néon / bleu électrique, noyau holographique animé et composants réutilisables.
- Navigation adaptative : barre latérale sur grand écran, rail sur écran intermédiaire, menu latéral sur mobile.
- Conversations avec messages utilisateur/assistant, états réel/en attente/erreur/annulation, copie et lecture vocale.
- Création, sélection, recherche et suppression de conversations ; historique JSON local versionné, écritures sérialisées et remplacement atomique.
- Contexte limité aux derniers messages de la conversation active. Ce n’est **pas** une mémoire sémantique à long terme.
- Modes **Local**, **Internet**, **Automatique**. Le mode automatique préfère un modèle Ollama réellement détecté, puis le fournisseur Internet configuré. Il ne bascule pas vers un autre fournisseur après une erreur de génération.
- **Ollama** : `/api/tags` et `/api/chat`, découverte des modèles installés, annulation de requête.
- **OpenAI** : `/v1/models` et `/v1/chat/completions`.
- **Anthropic** : `/v1/models` et `/v1/messages`, avec son schéma d’API distinct.
- **Groq** : `/openai/v1/models` et `/openai/v1/chat/completions`, clé personnelle isolée dans le stockage sécurisé.
- **Profil local léger** : `qwen3:0.6b-q4_K_M` via Ollama, contexte 2048, batch 128, réponse 512 tokens et déchargement après réponse. Poids publiés ≈ 523 Mo ; cible < 4 Gio pour le moteur, à mesurer, pas une garantie de RAM totale appareil.
- Paramètres persistants ; clés séparées par fournisseur dans le stockage sécurisé natif.
- Dictée à la demande et synthèse vocale natives, sous réserve des services et permissions de l’appareil. La reconnaissance Windows est expérimentale.
- Accent, halos, réduction des animations, langue et vitesse vocales, instructions générales et taille du contexte.
- Tests unitaires et widgets, CI d’analyse et de compilation Android/Windows.

**Important :** un connecteur compilé ne signifie pas qu’un serveur ou une clé est disponible. Les appels réels nécessitent votre propre infrastructure ou abonnement. Les fonctions vocales doivent être essayées sur le matériel cible.

## Configurer un moteur

Ouvrez **Paramètres → Moteurs IA**.

### Ollama

1. Installez et lancez Ollama sur votre machine, puis installez un modèle avec les commandes officielles d’Ollama. OPENUS n’installe aucun logiciel. Le profil léger proposé est `ollama pull qwen3:0.6b-q4_K_M`.
2. Renseignez l’origine du serveur, sans `/api` à la fin.
3. Cliquez sur **Vérifier et lister les modèles**, puis choisissez un modèle installé.
4. Enregistrez la configuration et choisissez le mode Local ou Auto.

`127.0.0.1` sur Android désigne le téléphone. Pour joindre le PC : adresse LAN du PC, `10.0.2.2` depuis l’émulateur Android, ou `adb reverse tcp:11434 tcp:11434` sur un appareil USB débogué. Un serveur local doit écouter sur une interface accessible ; ne l’exposez pas publiquement sans authentification et TLS.

### Groq

Voir [docs/GROQ_AND_LOCAL.md](docs/GROQ_AND_LOCAL.md). Créez votre clé sur `console.groq.com/keys`, collez-la uniquement dans le champ sécurisé de l’application, puis enregistrez. Ne la partagez pas dans le chat ou GitHub. Le modèle suggéré est `llama-3.1-8b-instant`, sous réserve d’accès de votre compte.

### OpenAI ou Anthropic

1. Choisissez le fournisseur.
2. Enregistrez votre propre clé avec le bouton dédié.
3. Indiquez l’identifiant exact d’un modèle autorisé pour votre compte. La vérification peut proposer les modèles déclarés par l’API.
4. Enregistrez et choisissez Internet ou Auto.

Les frais, quotas et politiques de traitement des données du fournisseur s’appliquent. Le mode Auto peut envoyer vos messages au fournisseur choisi si le moteur local n’est pas disponible.

## Vérifications

La CI de l’extension Groq/local est verte : formatage, analyse, 32 tests, APK Android debug et bundle Windows release. Voir [docs/VERIFICATION.md](docs/VERIFICATION.md). Aucun compte Groq réel, serveur Ollama installé ou mesure RAM matérielle n’a été testé dans le sandbox.

## Confidentialité et sécurité

- Aucune télémétrie OPENUS, aucun compte OPENUS, aucune synchronisation cloud des conversations.
- Les conversations sont stockées dans le répertoire privé de l’application, **non chiffrées par OPENUS**. La protection du système/compte utilisateur reste nécessaire.
- Les clés sont dans les chiffrements personnalisés du plugin Android adossés à Android Keystore, et dans le mécanisme AES-GCM / Credential Manager du plugin Windows. Elles ne sont pas dans `shared_preferences`, les conversations, les URLs ou le code source.
- Le champ de clé ne recharge jamais une clé enregistrée. Les erreurs HTTP ne contiennent ni corps de réponse ni en-têtes d’authentification.
- HTTP est limité par validation aux origines locales ; les fournisseurs Internet utilisent HTTPS. Android autorise le cleartext au niveau du manifest pour les serveurs locaux arbitraires : durcir cette politique avant une distribution large.
- Le micro n’est activé qu’à la demande. OPENUS ne conserve pas de fichier audio. Le service de reconnaissance Android peut utiliser le réseau.
- Les réponses sont affichées comme texte sélectionnable, pas comme HTML exécutable.
- Les fichiers de signature, secrets, propriétés locales et artefacts compilés sont exclus de Git.

## Architecture

```text
lib/
  core/       thème, constantes, identifiants, transport HTTP
  domain/     modèles et contrats indépendants de l’interface
  data/       historique, paramètres, stockage sécurisé
  services/
    ai/       Ollama, OpenAI, Anthropic, Groq, base OpenAI-compatible, routage
    memory/   construction du contexte conversationnel
    voice/    dictée et synthèse natives
  state/      contrôleurs ChangeNotifier
  ui/         écrans et composants réutilisables
android/      application Android, permissions, wrapper Gradle, signature optionnelle
windows/      runner natif CMake / Win32
assets/branding/ emplacement du logo officiel
 test/        tests et doublures exclusivamente de test
.github/workflows/ci.yml
```

Voir [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md), [docs/PHASE1_REPORT.md](docs/PHASE1_REPORT.md) et [docs/VERIFICATION.md](docs/VERIFICATION.md).

État vérifié : analyse, tests, APK Android debug et bundle Windows release compilés avec succès par la CI GitHub. Les essais avec moteurs IA réels et périphériques vocaux restent à effectuer.

## Logo officiel

Le logo fourni séparément n’était pas présent dans le dépôt initial. Déposez-le sous :

```text
assets/branding/openus_logo.png
```

Puis redémarrez l’application. `BrandMark` détecte ce fichier et l’utilise automatiquement. Un repère géométrique provisoire OPENUS est utilisé sinon. Les icônes lanceur Android/Windows sont également provisoires et devront être déclinées du logo officiel avant publication.

## Limites assumées de la phase 1

- Pas de llama.cpp/GGUF embarqué, de téléchargement de modèles, ni serveur Ollama inclus dans l’APK.
- Pas de streaming token par token, d’outils IA, d’exécution de commandes ou d’automatisation du PC/téléphone.
- Pas de mémoire personnelle sémantique, de mot de réveil ou de conversation vocale continue.
- Pas de sélection avancée des voix système ; moteur vocal par défaut.
- Pas d’installateur/signature Windows, de publication Play Store ou de signature release préconfigurée.
- Les réponses Markdown sont affichées en texte brut ; rendu riche à intégrer.

Une compilation CI ne remplace pas les essais réels sur téléphone, microphone, voix système, serveurs locaux et comptes API.