# Préparation Windows 10/11

Le runner natif est inclus pour préserver la compatibilité, même si la distribution Windows est prévue dans une prochaine phase.

## Prérequis

- Windows 10/11 x64.
- Flutter stable 3.44.9 recommandé.
- Visual Studio 2022 / Build Tools avec **Desktop development with C++**.
- SDK Windows, CMake et Ninja intégrés au workload.
- **C++ ATL** pour les bibliothèques de stockage sécurisé.
- Services vocaux et langues souhaitées installés dans Windows pour les fonctions audio.

```powershell
flutter doctor -v
flutter config --enable-windows-desktop
flutter pub get
flutter analyze
flutter test
flutter run -d windows
flutter build windows --release
```

Sortie attendue : `build/windows/x64/runner/Release/OPENUS.exe`, accompagné de DLL et du dossier `data`. Distribuer le dossier complet, pas l’EXE seul. Le nom binaire est défini par `BINARY_NAME` dans `windows/CMakeLists.txt`.

## À valider sur une vraie machine Windows

- Ouverture du stockage privé et remplacement atomique de l’historique.
- Enregistrement, relecture et suppression d’une clé avec Credential Manager.
- Microphone, permissions, langues et limites expérimentales de `speech_to_text`.
- Synthèse et voix système par défaut.
- Fenêtre redimensionnée, petits écrans, clavier et mise à l’échelle Windows.
- Fermeture pendant une requête et restauration de l’historique.

L’installateur MSIX/Inno Setup, la signature Authenticode, les mises à jour et l’icône officielle restent à réaliser. Aucune compilation Windows n’est possible depuis le sandbox Linux ; la CI utilise un runner Windows réel.
