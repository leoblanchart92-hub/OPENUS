# Audit préalable à fusion — PR #6

## Périmètre

Base main : 816df154d42200c4ab31722f237d9c694406674d.
PR #6 examinée : workflow Windows, manifeste, installateur, démarrage/app,
intégration Paramètres, service de conversation, checkpoint, updater, carte UI,
tests et documentation. Pas de modification de Nyx, des couleurs ou de la navigation.
Ni PR fusionnée, ni Release créée. Aucun logiciel installé sur le PC/USB utilisateur.

Les cinq fichiers de la PR #5 sont TOUS également modifiés dans #6 :
- .github/workflows/build-windows.yml
- installer/windows/Nexus-AI.iss
- lib/screens/settings_screen.dart
- lib/services/update_service.dart
- lib/widgets/update_card.dart

La PR #6 reprend les concepts de #5 et remplace ses parties non sécurisées.
Ne pas fusionner les deux comme changements indépendants : doublons/conflits et
régression possible de la sécurité. #5 reste ouverte, sans modification.

## Conclusion principale : pas de recommandation de fusion immédiate

**Bloquant : la persistance après fermeture ordinaire n'est pas implémentée.**
`UpdateCheckpoint.save()` n'est appelé par l'application que dans `beforeInstall`.
Aucun listener ne sauvegarde les modifications de ChatService/SettingsController
sur disque. `dispose()` ne les sauvegarde pas non plus. Sans mise à jour, une
session est perdue à la fermeture ; avec un ancien checkpoint, le prochain
redémarrage recharge cet ancien état et non les dernières modifications.
Un test de roundtrip du checkpoint ne constitue PAS une preuve de persistance
de l'application. Il faut une vraie sauvegarde des mutations, sérialisée et
récupérable, plus des essais de fermeture/réouverture avec données modifiées.
Cette lacune n'est volontairement pas cachée par un changement d'assertion.

## Checkpoint

Vérifié par tests unitaires : paramètres/conversations encodés et relus,
backup `.previous` conservé et utilisé si le fichier primaire est absent,
refus d'un schéma inconnu, refus d'un chemin non inscriptible, conservation des
fichiers lors d'un primaire corrompu. Un primaire corrompu ne déclenche PAS de
fallback automatique vers un backup valide : main affiche un écran de récupération
sans écraser les données, mais l'utilisateur ne dispose pas d'un outil de réparation.
L'entrée `.pending` n'est pas considérée au chargement.

Autres corrections à prévoir avant une garantie de conservation forte :
- verrouiller/sérialiser les écritures et gérer plusieurs instances ;
- empêcher les changements UI entre la capture du snapshot et la fermeture
  (l'application reste utilisable pendant l'attente d'écriture) ;
- conserver si nécessaire la conversation active, actuellement non sérialisée ;
- tester l'échec de lancement du Setup après checkpoint, les arrêts forcés et
  la restauration après installation interrompue, pas seulement le JSON isolé.
- donner au support un diagnostic exploitable : main masque la cause originale
  de lecture du checkpoint dans catch (_), même si un message utilisateur apparaît.

Le Setup de mise à jour est lancé détaché, sans suivi de son code de sortie et
sans /LOG explicite, puis l'application se ferme. Un échec d'installation ultérieur
n'est pas remonté par l'application. Prévoir un journal persistant et un protocole
de résultat/reprise ; Process.start réussi ne signifie pas installation réussie.

## Sécurité du téléchargement

Revue de code et tests : URL initiale HTTPS EXACTE du dépôt/tag/asset attendu,
refus d'autres dépôts/hôtes, credentials, ports non standards, query/fragment.
L'API de métadonnées ne suit pas les redirections. Les redirections d'assets
sont désactivées au niveau HttpClient et suivies explicitement, au maximum quatre
requêtes, seulement vers release-assets.githubusercontent.com (HTTPS sans
credentials, port non standard ou fragment ; query signée autorisée).
L'audit ajoute le refus des fragments de redirection et un timeout de vidage
de réponse. Les tests couvrent la politique pure ; ce n'est pas une preuve d'une
transaction HTTP réelle comprenant erreurs, coupures réseau et relances.

Métadonnées : draft/prerelease ignorées ; tag stable strict ; asset manquant ou
dupliqué refusé ; digest absent/malformé et taille insuffisante refusés.
Fichier : taille exacte + SHA-256 en streaming avant Process.start ; tests positifs,
troncature et altération de même taille. Un téléchargement trop grand est coupé.
Une recherche/installation nécessite la confirmation via la carte, et l'installation
est bloquée en cours d'une autre installation dans le même processus.
SetupMutex bloque deux installateurs, PAS deux instances d'application écrivant
le même checkpoint. Les fichiers temporaires d'une installation lancée restent
sur disque. SHA-256 ne remplace pas une signature Authenticode et ne protège pas
contre la compromission du compte GitHub ou d'un autre processus du même utilisateur.

Améliorations restantes : tests de transport injecté avec timeout, redirection
refusée et stream tronqué ; test prouvant l'absence d'exécution dans chaque cas ;
limite de durée totale de téléchargement ; validation des deux entrées exactes et
uniques du manifeste SHA256SUMS lors de publication (actuellement chaque ligne
présente est vérifiée, sans exiger les deux lignes).

## Version

Source unique : pubspec.yaml = 0.1.1+2 ; asset embarqué lu par l'UI.
Flutter fournit les ressources natives ; le smoke test exige FileVersion numérique
0.1.1.2. UI/comparaison/Release/Inno AppVersion utilisent la partie stable 0.1.1,
et le tag attendu est v0.1.1. Aucun input indépendant de version dans le workflow.
La partie +2 n'est pas affichée dans l'UI ni injectée comme quatrième composante
de VersionInfoVersion du Setup. Cohérence de version stable, pas identité de tous
les champs de version. Pour distinguer deux builds d'une même version, ajouter
la propagation du build et définir explicitement la politique d'updates : le
comparateur actuel ne distribue pas 0.1.1+3 comme nouvelle version de 0.1.1+2.

## Essais distants et limites

Un nouveau paramètre manuel `verify_installer` (défaut false) du workflow existant
active installer/windows/verify-installer.ps1. Il est restreint à un runner GitHub
Windows et refuse d'écraser une installation ou des données déjà présentes.
Il installe le vrai Setup, vérifie chemin utilisateur/HKCU/fichiers/raccourcis,
ouvre et ferme l'exécutable, réinstalle avec /RELAUNCH=1, désinstalle et contrôle
la conservation exacte d'un fichier JSON témoin extérieur. Ce témoin n'est pas
une conversation saisie dans l'UI. Le compte runner peut être administrateur :
ces tests ne prouvent pas l'absence d'UAC sous un vrai compte standard.

Premier essai : https://github.com/leoblanchart92-hub/OPENUS/actions/runs/42588749841
Analyse et tous les tests Flutter, build, packaging et compilation Inno réussis.
Smoke test échoué avec `Application exited with ` (ExitCode vide dans le harness).
Les contrôles avant ce point ont passé ; pas de preuve de désinstallation/relaunch
sur cet essai. Correction du harness : conserver le handle du processus avant
fermeture et traiter un ExitCode absent comme erreur explicite. Échec conservé
sur GitHub, jamais désactivé ni supprimé.

Second essai : https://github.com/leoblanchart92-hub/OPENUS/actions/runs/42589334488
**SUCCÈS**, commit testé 09396c9fbc21dc682492d335c5fe48a3dfc57979 :
pub get, flutter analyze, tous les tests Flutter (dont les nouveaux scénarios),
compilation Windows, bundle, compilation Inno, smoke test d'installation,
réinstallation/relance, désinstallation et conservation du témoin : tous réussis.
Codes de sortie Setup/application/uninstaller contrôlés à zéro par le script.
Version native contrôlée à 0.1.1.2. Artifacts et diagnostics téléversés.
Job de publication ignoré, publish_release=false. Ce résultat n'efface pas
le premier échec ni les limitations sur la persistance réelle des sessions.

Toujours non démontré : interaction graphique complète et édition/relecture de
vraies données après redémarrage, compte standard/UAC/SmartScreen, Windows 10/11
utilisateur, upgrade entre deux versions signées/publiées, annulation et interruption
de Setup. Certaines vérifications sont automatisables sur des VM Windows isolées ;
elles ne sont pas impossibles à distance, mais ne sont pas couvertes par ce smoke
test de runner. Aucun besoin d'utiliser le PC de l'utilisateur pour les effectuer.
