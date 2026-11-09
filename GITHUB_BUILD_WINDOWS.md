# Nexus AI — build Windows avec GitHub Actions

## 1. État réel

**État historique de phase 7 : workflow créé localement, mais non publié ni exécuté sur GitHub pendant cette phase. Aucun exécutable n’a encore été produit ou vérifié par un build réel.**

Fichiers créés :

- `.github/workflows/build-windows.yml`
- `GITHUB_BUILD_WINDOWS.md` (ce rapport)

Aucun fichier existant modifié ou supprimé. Aucun commit, push, réécriture d’historique, changement de paramètres GitHub/Windows ou déclenchement distant effectué. Nyx, le design, le compact, Groq et les dépendances de l’application sont inchangés. Aucun logiciel installé sur le PC de l’utilisateur, aucun accès USB.

## 2. Dépôt, branche et accès vérifiés

- Remote Git `origin` : **`https://github.com/leoblanchart92-hub/OPENUS.git`**.
- Dépôt confirmé par `gh repo view` et l’API : **[leoblanchart92-hub/OPENUS](https://github.com/leoblanchart92-hub/OPENUS)**.
- Branche locale : **`arena/6757039f-openus`**.
- Branche par défaut distante : **`main`**.
- `viewerPermission` retourné : **ADMIN** ; l’API du dépôt annonce aussi `push: true` et `admin: true`.
- La liste des workflows distants est accessible ; elle contient déjà `OPENUS foundations` à `.github/workflows/ci.yml`. Il n’a pas été remplacé ou modifié.
- La lecture de `repos/leoblanchart92-hub/OPENUS/actions/permissions` renvoie **HTTP 403 — Resource not accessible by integration**. L’intégration courante n’a donc pas accès à ce réglage. Les politiques d’activation Actions, d’approbation des actions tierces, les quotas et la possibilité d’écrire des fichiers workflow avec cette intégration ne sont pas certifiés par les seuls droits du dépôt.

Le dépôt est bien relié à GitHub. Il ne manque pas son adresse ; il manque encore une **publication autorisée des sources et du workflow**, et la confirmation des politiques Actions par le propriétaire. Aucun secret, mot de passe, token ou clé API n’est demandé ou inscrit dans le workflow.

## 3. Configuration du workflow

- Nom affiché : **Build Nexus AI Windows**.
- Job : **Windows x64 release**.
- Runner hébergé GitHub : **`windows-2022`**, architecture x64 contrôlée avant build.
- Flutter fixé sur **`3.47.9`, canal `stable`, architecture SDK x64**.
- Le tag officiel `flutter/flutter` **3.47.9** a été vérifié par API : son SHA complet est **`c197ca5199e9ee5661e865596c9c07294dfab51c`**. Il correspond aussi à la révision stable des templates utilisés pour préparer les runners. Ce choix évite de suivre aveuglément une future version stable ; sa compatibilité réelle avec l’application reste à éprouver par le premier run.
- Actions checkout, setup Flutter et upload-artifact référencées par SHA immuable, résolu depuis leurs références v4/v2/v4 lors de cette phase.
- Permission du token du job : **`contents: read`**, sans accès en écriture demandé ; checkout sans persistance d’identifiants.
- Aucun secret applicatif, environnement Groq ou appel à un fournisseur IA.
- Délai maximum du job : 45 minutes. Un nouveau run de la même référence peut annuler le précédent.

L’installation Flutter et les téléchargements nécessaires sont prévus **uniquement sur le runner GitHub éphémère**, pas sur le poste utilisateur. La phase actuelle n’a pas exécuté cette installation.

### Déclencheurs — mise à jour de phase 8

- **Manuel uniquement : `workflow_dispatch`.** Les déclencheurs push/PR ont été retirés avant publication pour respecter l’absence d’autorisation d’exécution distante.
- Publier cette branche ne déclenche donc pas ce build Windows.
- Aucun `pull_request_target`, aucune publication Release automatique.

## 4. Étapes et conditions d’arrêt

1. Checkout des sources.
2. Vérification des sources Windows, de l’icône, du nom `nexus_ai` et des six méthodes du canal `nexus_ai/desktop_window`.
3. Installation Flutter sur le runner hébergé, affichage Flutter/Dart et activation desktop dans ce runner seulement.
4. **`flutter pub get`**, puis copie du lockfile réellement résolu dans les diagnostics.
5. **`flutter analyze --no-pub`**.
6. **`flutter test --no-pub --reporter expanded`**, incluant les tests de phase 5.
7. **`flutter build windows --release --no-pub -v`**. Le runner et le SDK sont x64. L’implémentation officielle de la commande Windows du SDK 3.47.9 a été examinée : elle choisit la cible selon l’hôte ; aucun flag d’architecture non pris en charge n’a été inventé.
8. Vérification du répertoire **`build/windows/x64/runner/Release`** : `nexus_ai.exe`, `flutter_windows.dll`, `data/icudtl.dat`, `data/app.so` non vides, dossier `data/flutter_assets`, et fichiers Flutter générés présents.
9. Copie de **tout** le répertoire Release, pas seulement de l’exécutable, vers `distribution/Nexus-AI-Windows`.
10. Copie des DLL du runtime MSVC x64 depuis le répertoire redistribuable de Visual Studio installé sur le runner, trouvé par `vswhere`. Pas de copie arbitraire de DLL depuis System32. Vérification explicite de `msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`. Le runtime système UCRT de Windows 10/11 reste une condition de l’OS.
11. Création de **`artifacts/Nexus-AI-Windows.zip`**, contenant le dossier `Nexus-AI-Windows/` et son bundle complet ; vérification des entrées principales du ZIP, calcul SHA-256 et inventaire des fichiers.
12. Publication de l’archive comme artefact **`Nexus-AI-Windows`**.
13. Publication séparée des diagnostics avec `if: always()`, même si analyse/tests/build ont échoué.

Chaque commande Flutter/Dart vérifie explicitement `$LASTEXITCODE` après l’écriture de son log et lève une erreur en cas d’échec. Il n’y a pas de `continue-on-error` ni de commande `|| true`. Un échec d’analyse ou de test empêche le build ; un échec de build/packaging empêche la publication du ZIP. Les étapes suivantes de diagnostic ne convertissent pas le job en réussite.

Le packaging échoue si les redistribuables ou sorties attendues manquent : il ne publie pas un bundle partiel comme s’il était complet. La disponibilité et les conditions de redistribution du runtime Microsoft restent à vérifier avant une diffusion commerciale.

## 5. Comment publier et lancer — après autorisation

### Attention à l’état des sources

À la fin des phases précédentes, une grande partie de l’application est encore **non suivie par Git** dans ce workspace. Publier uniquement le nouveau workflow ne suffira pas : GitHub doit aussi recevoir `pubspec.yaml`, les sources `lib/`, les tests, le runner `windows/` et les configurations nécessaires. Un simple clone de l’état distant actuel peut ne pas contenir le projet préparé.

Aucun commit/push n’a été effectué ici. Avant toute publication : revue des fichiers et de l’absence de secrets, puis autorisation explicite. La seule branche de travail de cette session reste `arena/6757039f-openus` ; pas de push direct sur `main` depuis cette session.

### Publication sans exécution

La phase 8 autorise le commit et le push des sources Windows, tests, configurations et de ce workflow, pas son exécution. Le workflow est désormais manuel uniquement. Aucune commande `gh workflow run` n’est exécutée pendant la publication.

Les paramètres Actions restent à vérifier par le propriétaire en cas de refus ; aucune erreur HTTP 403 ne doit être contournée.

### Lancement manuel

Pour que `workflow_dispatch` soit disponible normalement depuis l’interface et l’API, le fichier workflow doit exister sur la branche par défaut **`main`**. Une publication sur la branche de session ne déclenche aucun run et ne garantit pas immédiatement le bouton manuel. L’intégration dans `main` doit suivre une PR/revue et une autorisation distincte ; aucun merge n’a été effectué ici.

Une fois le workflow disponible sur la branche par défaut :

1. Actions → **Build Nexus AI Windows** → **Run workflow**.
2. Choisir la branche contenant les sources complètes, par exemple `arena/6757039f-openus` si elle est toujours disponible.
3. Cliquer **Run workflow**, puis ouvrir le run créé.

Alternative CLI, **à exécuter seulement après publication et autorisation de lancement** :

```bash
gh workflow run build-windows.yml --repo leoblanchart92-hub/OPENUS --ref arena/6757039f-openus
gh run list --repo leoblanchart92-hub/OPENUS --workflow build-windows.yml
```

Aucun identifiant de run n’est fourni ici, car aucun run n’a été lancé par cette phase.

## 6. Emplacement exact du ZIP et des logs

Dans GitHub :

**Dépôt → Actions → Build Nexus AI Windows → run concerné → section Artifacts**.

- Artefact **`Nexus-AI-Windows`** : contient le fichier **`Nexus-AI-Windows.zip`**.
- Artefact **`Nexus-AI-Windows-logs`** : logs de versions/résolution/analyse/tests/build, inventaire de distribution, SHA-256 et diagnostics CMake disponibles.
- Rétention demandée : **14 jours**, sous réserve de la politique du dépôt.

Le téléchargement web d’un artefact GitHub est lui-même une archive : selon l’interface, il faut donc extraire l’enveloppe GitHub pour obtenir notre `Nexus-AI-Windows.zip`, puis extraire celle-ci. À l’intérieur : **`Nexus-AI-Windows/nexus_ai.exe`**, accompagné de ses DLL et de `data/`.

Ne pas lancer l’exécutable directement dans le ZIP et ne pas copier l’exécutable seul. Extraire le bundle entier dans un dossier local. Il ne s’agit pas d’un installateur signé.

Avec un identifiant réel lu dans la liste des runs, `gh run download <ID_REEL> --repo leoblanchart92-hub/OPENUS --name Nexus-AI-Windows --dir ./download` récupère le contenu de l’artefact ; le ZIP se trouve alors dans `./download/Nexus-AI-Windows.zip`. Remplacer le placeholder par un ID réel, pas un identifiant inventé.

Si le job échoue, consulter le step rouge et les diagnostics ; le ZIP de distribution peut légitimement être absent. Les logs standards des étapes restent également dans le run GitHub. Relire les logs avant tout partage public, même si aucun secret applicatif n’est utilisé.

## 7. Contrôles réellement effectués ici

- Vérification remote, branche active, dépôt, droits déclarés et liste des workflows par Git/`gh`.
- Constat explicite du 403 sur les paramètres Actions ; aucun contournement ni changement de permissions.
- Vérification du tag Flutter stable 3.47.9 et de sa révision ; lecture de la commande officielle `build_windows.dart` et des paramètres de l’action setup Flutter.
- Résolution des SHA des trois actions utilisées.
- Revue textuelle du workflow : permissions minimales, ordre des étapes, arrêts sur code non nul, vérification du bundle/ZIP et récupération des diagnostics.
- `python3 tools/audit_static.py` : code **0**, 43 fichiers Dart contrôlés structurellement, 19 XML et 2 JSON parsés, zéro erreur dans ces contrôles.
- `git diff --check` : code **0**.

Aucun parseur YAML/actionlint n’est disponible localement ; la validation complète de syntaxe GitHub Actions reste à obtenir lors de sa publication. Les contrôles locaux de structure ne simulent ni PowerShell, ni Flutter, ni Visual Studio. **Aucun build, test Flutter, ZIP ou artefact GitHub issu de ce workflow n’est annoncé produit.**

## 8. Limites et prochaine décision

- Les erreurs d’analyse ou de tests non encore exécutés peuvent arrêter le premier run avant compilation ; elles doivent être corrigées selon les logs réels, sans désactiver les contrôles.
- Le runner `windows-2022` est un environnement Windows Server de compilation. Produire un binaire x64 ciblant Windows 10/11 ne prouve pas le fonctionnement sous les deux OS. Essais réels du bundle sur Windows 10 et 11 encore nécessaires, notamment compact, topmost, DPI, déplacement et erreurs/reprise.
- Le job ne lance pas un test GUI natif du binaire et ne valide pas une installation sur un PC propre.
- Les fichiers Flutter générés restent générés par Flutter, pas inventés. Le lockfile n’existe pas encore dans les sources ; le run conserve sa résolution en diagnostic. La figer dans le dépôt sera une décision après une résolution réelle.
- L’image runner et les services GitHub peuvent évoluer malgré le SDK Flutter et les actions fixés ; la disponibilité de leurs téléchargements et des redistribuables sera vérifiée par le run.
- Quotas Actions, autorisation d’actions tierces et écriture des workflows via l’intégration à confirmer. La permission ADMIN du dépôt ne remplace pas ces contrôles.

**Prêt : workflow et procédure de lancement/artifact. En attente : autorisation de publication des sources complètes, validation des politiques Actions et première exécution réelle. Nexus AI n’est pas encore déclaré compilé.**


## 9. Publication autorisée — phase 8

Le périmètre à publier est limité au workflow manuel, à ce document, à `.gitignore`, `pubspec.yaml`, `analysis_options.yaml`, `lib/`, `test/` et `windows/`. Ces sources sont indispensables pour que le checkout GitHub soit compilable ; publier uniquement le YAML ne suffirait pas. Les projets Android/iOS, les rapports précédents, les outils locaux et le README modifié restent hors de ce commit. Aucun lancement distant autorisé à cette étape. Le résultat effectif du commit/push doit être vérifié séparément, et ne peut pas être déduit de ce document.
