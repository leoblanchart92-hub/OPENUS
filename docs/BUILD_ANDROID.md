# Construire le premier APK OPENUS

## Poste de développement

- Flutter stable 3.44.9 recommandé (minimum déclaré : 3.38).
- JDK 17.
- Android SDK, platform SDK 36, build-tools et NDK indiqués par `flutter doctor` pour le SDK choisi.
- Un téléphone Android API 24+ ou un émulateur, avec débogage USB activé si nécessaire.
- Plusieurs Go d’espace libre pour Flutter, Gradle et le SDK Android. Rien n’est installé sur une clé USB par ces commandes.

```bash
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <id-appareil>
```

## APK de développement

```bash
flutter build apk --debug
```

Fichier attendu : `build/app/outputs/flutter-apk/app-debug.apk`.

Installation :

```bash
flutter install -d <id-appareil>
# ou : adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

L’APK debug utilise l’identité debug générée par les outils Android sur le poste. Il ne convient pas à une publication. L’identifiant applicatif est `com.openus.assistant` ; choisissez un identifiant vous appartenant avant toute publication et avant de figer les données utilisateurs.

## Signature release locale

Ne commitez jamais le keystore ou ses mots de passe. Créez-le dans votre espace utilisateur, hors dépôt :

```bash
keytool -genkeypair -v -keystore "$HOME/.android/openus-release.jks" \
  -keyalg RSA -keysize 2048 -validity 10000 -alias openus
```

Créez `android/key.properties`, ignoré par Git, avec vos propres valeurs :

```properties
storeFile=/chemin/absolu/vers/openus-release.jks
storePassword=<votre-mot-de-passe>
keyAlias=openus
keyPassword=<votre-mot-de-passe>
```

Les chevrons ci-dessus sont des instructions de remplacement, pas des mots de passe fonctionnels. Sous Windows, utilisez un chemin absolu Windows dans `storeFile`.

```bash
flutter build apk --release
```

Sans `key.properties`, aucune identité release n’est configurée et le build n’utilise pas silencieusement une signature debug. Utilisez le build debug pour les premiers essais. Conservez une sauvegarde sûre de la clé release : sa perte empêche les mises à jour signées de la même application.

Pour le Play Store, la commande habituelle est `flutter build appbundle --release`, après validation de l’identifiant, de la signature, des règles de confidentialité et des exigences de publication.

## Ollama pendant les essais

- Émulateur Android vers Ollama sur le PC : `http://10.0.2.2:11434` si le serveur est accessible depuis l’émulateur.
- Téléphone USB : `adb reverse tcp:11434 tcp:11434`, puis `http://127.0.0.1:11434` dans OPENUS.
- Réseau local : adresse IP LAN du PC et port accessibles, pare-feu configuré avec le minimum de permissions. Utilisez HTTPS pour un serveur distant.

Ne modifiez pas `OLLAMA_HOST` pour exposer un serveur non authentifié sur Internet. OPENUS ne télécharge pas de modèle et ne démarre pas Ollama.

## CI

`.github/workflows/ci.yml` exécute pub get, formatage, analyse, tests, compilation Android debug et compilation Windows release. Les artefacts CI sont des builds de développement/validation, pas des releases signées pour distribution. Consultez le rapport de phase pour les résultats réellement obtenus.
