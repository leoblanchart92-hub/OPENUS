# Vérifications réelles — OPENUS phase 1

Date : **2026-11-06**
Branche : `arena/57c93823-openus`
Commit de code vérifié : `f8aa53027ff1032a45a4e09c80a07f869f5b90be`
Exécution GitHub Actions : **success**
https://github.com/leoblanchart92-hub/OPENUS/actions/runs/42167577745

## Résultats observés

| contrôle | commande / étape | résultat |
|---|---|---|
| Résolution des dépendances | `flutter pub get` | réussi sur les runners Ubuntu et Windows |
| Formatage | `dart format --output=none --set-exit-if-changed lib test` | réussi |
| Analyse statique | `flutter analyze --no-pub` | réussi, aucun problème remonté |
| Tests | `flutter test --no-pub --reporter expanded` | réussi ; la suite contient 24 tests unitaires/widgets |
| Stockage Windows | `flutter test --no-pub test/storage_test.dart` | réussi sur `windows-latest` |
| APK Android | `flutter build apk --debug --no-pub` | réussi ; artefact `OPENUS-android-debug` |
| Bundle Windows | `flutter build windows --release --no-pub` | réussi ; artefact `OPENUS-windows-release` |

Artefacts produits par cette exécution :

- `OPENUS-android-debug` : 79 190 325 octets, APK **debug** signé par l’identité debug du runner, destiné aux essais.
- `OPENUS-windows-release` : 13 218 565 octets, dossier runner Windows contenant l’EXE et ses ressources ; pas un installateur signé.

Les artefacts sont conservés 7 jours par la CI. Ils ne sont pas versionnés dans Git.

## Jobs

- Analyze & test : https://github.com/leoblanchart92-hub/OPENUS/actions/runs/42167577745/job/127727504527
- Windows release build : https://github.com/leoblanchart92-hub/OPENUS/actions/runs/42167577745/job/127727504774
- Android debug APK : https://github.com/leoblanchart92-hub/OPENUS/actions/runs/42167577745/job/127727504884

## Limites de la vérification

Le sandbox local ne pouvait pas télécharger le Dart SDK nécessaire au démarrage de Flutter depuis `storage.googleapis.com`, domaine hors de la liste réseau autorisée. Les commandes Flutter locales n’y ont donc **pas** été présentées comme réussies. Les vérifications ci-dessus ont été exécutées sur de vrais runners GitHub Actions.

Aucun test fonctionnel réel n’a été effectué avec :

- un serveur Ollama et un modèle local installé ;
- une clé OpenAI ou Anthropic personnelle ;
- un microphone, une voix système ou un appareil Android physique ;
- le lancement runtime du bundle Windows sur un poste utilisateur ;
- une signature release Android, une publication Play Store ou un installateur Windows.

Ces essais restent nécessaires avant distribution. Une compilation réussie ne prouve pas la disponibilité d’un moteur IA ni la présence des services vocaux sur chaque appareil.

## Notices restantes

La CI remonte une notice non bloquante de GitHub sur la migration future de `ubuntu-latest` vers Ubuntu 26. Elle n’affecte pas la réussite des jobs actuels. Les avertissements Node.js 20 ont été traités en mettant à jour les actions utilisées.
