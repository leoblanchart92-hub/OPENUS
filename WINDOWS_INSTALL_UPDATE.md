# Installation et mises à jour Windows

## État et provenance

Cette implémentation reprend et sécurise les idées de la PR #5 (non fusionnée),
sur main incluant les PR #1–#4. Elle ne modifie ni Nyx ni le thème.
`pubspec.yaml` est l'unique source de version : 0.1.1+2. Flutter utilise ce
manifest, l'interface lit sa copie embarquée, et le workflow extrait 0.1.1 pour
Inno Setup et la Release v0.1.1. Les préversions ne sont pas distribuées.

## Produire le premier Setup

Après revue et fusion autorisée de cette PR : Actions → Build Nexus AI Windows
→ Run workflow → main. Laisser publish_release=false pour un essai.
Le workflow analyse, teste, compile, copie tout le bundle Flutter et les DLL
MSVC app-local, crée le ZIP et utilise Inno Setup de l'image Windows hébergée.
Un compilateur absent entraîne une erreur explicite, jamais un faux Setup.
Les artefacts Nexus-AI-Windows et Nexus-AI-Setup contiennent les binaires et
SHA256SUMS.txt. Télécharger Nexus-AI-Setup.exe et le lancer : installation dans
LOCALAPPDATA/Programs/Nexus AI, sans élévation, raccourci menu Démarrer et Bureau
optionnel. L'identifiant Inno stable assure la réinstallation au même endroit.
Désinstallation via les paramètres Windows ; aucune directive ne supprime les
données LOCALAPPDATA/NexusAI. Le Setup n'est pas signé : SmartScreen peut avertir.

## Publier volontairement

Pour une distribution réelle, augmenter la version dans pubspec.yaml, fusionner,
puis lancer manuellement le même workflow sur main avec publish_release=true.
Il crée une Release brouillon ciblant exactement GITHUB_SHA, téléverse Setup,
ZIP et checksums puis rend la Release publique. Un tag existant fait échouer la
création : pas d'écrasement. Contrôler les notes avant distribution, les compléter
via GitHub si nécessaire. Aucun trigger push, PR ou planifié.

## Contrat de sécurité de l'updater

Recherche au démarrage Windows (la carte Paramètres est montée par IndexedStack)
et bouton manuel. Une version identique ou plus ancienne ne produit aucune alerte
automatique. Notes et version sont affichées avant le consentement.
Seuls les assets de leoblanchart92-hub/OPENUS sont acceptés : URL GitHub exacte,
HTTPS et redirections limitées au stockage officiel release-assets.githubusercontent.com.
L'API officielle doit fournir digest=sha256:… et une taille valide ; sinon refus.
Le fichier temporaire doit avoir exactement cette taille et ce SHA-256 avant
exécution. Aucun secret nécessaire. Un seul téléchargement/installation à la fois
par processus, et SetupMutex bloque plusieurs installateurs simultanés.
Les erreurs de recherche automatique restent discrètes ; celles d'une installation
confirmée sont visibles. Le téléchargement partiel est supprimé en cas d'échec.
Un Setup lancé reste en temporaire (nettoyage Windows ultérieur).

Avant lancement, un checkpoint de paramètres et de toutes les conversations est
écrit avec flush hors du dossier programme, avec sauvegarde précédente et reprise
si interruption entre renommages. Une réponse en cours bloque l'installation.
Au redémarrage Windows le checkpoint est restauré ; une corruption ne provoque
pas sa réinitialisation silencieuse. Cette fonctionnalité est un checkpoint de
mise à jour, PAS encore une sauvegarde continue de chaque conversation entre
redémarrages ordinaires. Les anciennes versions en mémoire ne peuvent pas être
récupérées rétroactivement. Le consentement lance le Setup silencieux puis demande
la fermeture native de Flutter ; /RELAUNCH=1 relance après installation réussie.
Inno gère les fichiers verrouillés. Aucun rollback transactionnel de toute
l'installation ni signature Authenticode n'est promis.

## Validation et limites

Tests ajoutés : comparaison stable numérique, refus des URL non officielles,
SHA-256/taille (altération et troncature), checkpoint et sauvegarde de secours,
version embarquée. Aucun test existant supprimé. Exécuter Validate Flutter et
Build Nexus AI Windows sur la branche exacte. Ne pas confondre analyse de source,
réussite du runner et validation utilisateur : installation, désinstallation,
fichiers verrouillés, relance et upgrade réel entre deux Releases demandent
encore des essais Windows isolés. Pas de droits administrateur ni d'installation
sur le PC utilisateur ou une clé USB pendant le développement.
