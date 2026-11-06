# Groq et profil local léger

Cette extension ajoute **Groq** comme fournisseur Internet et un **profil local léger réel** pour Ollama. Elle n’embarque ni Ollama, ni poids de modèle, ni clé API dans OPENUS. Aucun téléchargement ou installation n’est lancé silencieusement.

## 1. Groq : votre clé, votre compte

1. Créez une clé personnelle sur **https://console.groq.com/keys**.
2. Dans OPENUS : **Paramètres → Moteurs IA → IA Internet → Groq**.
3. Le champ modèle propose `llama-3.1-8b-instant` comme point de départ documenté. Remplacez-le par un identifiant autorisé pour votre compte si nécessaire.
4. Collez la clé dans le champ masqué, puis cliquez sur **Enregistrer la clé**. Elle va dans le stockage sécurisé natif, sous un emplacement propre à Groq (`openus.api.groq.v1`). Elle n’est pas écrite dans les préférences, l’historique, le code ou Git.
5. Cliquez sur **Vérifier l’API et lister les modèles**, puis **Enregistrer la configuration**.
6. Choisissez **Internet** pour utiliser uniquement Groq, ou **Auto** pour préférer Ollama quand il est réellement disponible.

Ne partagez jamais votre clé dans le chat, une capture d’écran, un dépôt GitHub ou un fichier de configuration. OPENUS ne fournit aucune clé. L’endpoint utilisé est `https://api.groq.com/openai/v1/chat/completions`, avec authentification Bearer. Les quotas, l’accès aux modèles, la facturation et la politique de données de Groq dépendent de votre compte ; une suggestion de modèle ne garantit pas son accès.

Groq est un service **cloud**. La cible mémoire locale ci-dessous ne s’applique pas aux modèles exécutés par Groq.

## 2. Local léger : Qwen3 0,6B Q4_K_M via Ollama

Le profil proposé est :

```text
Modèle : qwen3:0.6b-q4_K_M
Poids publiés : environ 523 Mo
Contexte : 2048 tokens
Batch : 128
Réponse maximale : 512 tokens
Thinking Qwen3 : désactivé
Après réponse : keep_alive = 0, déchargement du modèle
Contexte conversationnel envoyé : 8 derniers messages
```

### Installation séparée

Installez Ollama depuis sa documentation officielle sur la machine qui exécutera le modèle, puis téléchargez le poids :

```bash
ollama pull qwen3:0.6b-q4_K_M
```

Dans OPENUS, cliquez sur **Choisir ce profil**, vérifiez l’adresse du serveur, enregistrez, puis **Vérifier et lister les modèles**. Le modèle doit apparaître dans la réponse réelle d’Ollama. Choisissez le mode **Local** pour interdire tout repli cloud, ou **Auto** si vous acceptez le fournisseur Internet configuré en repli de sélection.

Le bouton de profil ne télécharge rien : il sélectionne le modèle et active les limites. La commande peut être copiée depuis l’application. OPENUS ne modifie pas les fichiers système et n’installe rien sur une clé USB.

### Ce que signifie « moins de 4 Go »

- **523 Mo** est la taille publiée du fichier de poids, pas la RAM totale utilisée.
- Le moteur ajoute cache KV, buffers de calcul, allocator et structures runtime. Le contexte 2048, le batch 128 et la réponse 512 réduisent ces besoins ; `keep_alive: 0` libère le modèle après la réponse, au prix d’un rechargement à la question suivante.
- La cible est **moins de 4 Gio pour le moteur Ollama avec ce profil**, pas moins de 4 Gio pour tout le PC. Windows, OPENUS, antivirus, navigateur et autres applications s’ajoutent.
- Le profil refuse les poids **connus** au-delà de 2 Gio afin de garder une marge. Ce garde-fou est heuristique : il ne mesure pas la RAM et ne peut pas plafonner le système d’exploitation.
- Aucune mesure matérielle n’a été effectuée dans le sandbox. Ne considérez pas la cible comme garantie sur votre machine.

### Mesurer sur votre appareil

Pendant une génération, observez le processus Ollama/runner dans le Gestionnaire des tâches Windows, ou utilisez :

```bash
ollama ps
```

Après une réponse, `keep_alive: 0` peut déjà avoir déchargé le modèle : une mesure à ce moment-là ne représente pas le pic pendant l’inférence. Relevez aussi la mémoire totale disponible dans le système. Sur une machine de 4 Gio au total, fermez les applications lourdes ; la marge peut rester insuffisante selon l’OS et le backend.

### Android

L’APK OPENUS ne contient pas Ollama ni le modèle. Sur Android, le profil léger utilise un **serveur Ollama externe** (PC du réseau local, émulateur via `10.0.2.2`, ou `adb reverse`). `127.0.0.1` désigne le téléphone. Une inférence entièrement embarquée sur le téléphone demanderait un moteur natif supplémentaire, par exemple llama.cpp/GGUF, et des tests ABI/RAM/appareil ; ce n’est pas livré ici.

## 3. Modes et confidentialité

- **Local** : uniquement Ollama ; aucun repli Groq/OpenAI/Anthropic si le serveur ou le modèle manque.
- **Internet** : uniquement le fournisseur choisi ; aucun appel Ollama.
- **Auto** : préfère un modèle local réellement détecté, sinon le fournisseur Internet configuré. Pas de second fournisseur après le début d’une génération.
- Les clés OpenAI, Anthropic et Groq restent séparées. Changer de fournisseur vide le champ de saisie et ne recharge jamais une clé enregistrée.
- En mode local, vérifiez que l’endpoint Ollama est bien une inférence locale que vous contrôlez ; un serveur Ollama distant ou une configuration cloud sort du périmètre « local ».

## 4. Vérification

Les tests automatisés couvrent le schéma Groq, l’isolation des clés, l’absence de repli local→cloud, les options Ollama légères, le garde-fou de taille, la migration des préférences et le formulaire mobile. La CI compile Android et Windows. Ils ne remplacent pas un essai avec votre clé Groq, un serveur Ollama réel et une mesure RAM sur l’appareil cible. Voir [VERIFICATION.md](VERIFICATION.md).
