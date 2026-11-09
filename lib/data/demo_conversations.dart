import '../core/models/chat_message.dart';
import '../core/models/conversation.dart';

/// Clearly marked demonstration conversations loaded on startup.
abstract final class DemoConversations {
  static List<Conversation> createInitial() {
    final now = DateTime(2026, 11, 9, 10, 30);

    return [
      Conversation(
        id: 'demo-welcome',
        title: 'Découverte de Nexus AI & Nyx',
        topicTag: 'Démo • Accueil',
        updatedAt: now,
        isDemo: true,
        messages: [
          ChatMessage(
            id: 'm1',
            sender: MessageSender.assistant,
            content:
                'Bienvenue dans Nexus AI ! Je suis Nyx, votre compagnon '
                'futuriste. Cette conversation utilise des données de '
                'démonstration locales pour tester l’interface, les bulles de '
                'discussion et mes animations.',
            timestamp: now.subtract(const Duration(minutes: 6)),
            isDemo: true,
            providerLabel: 'Démo locale',
          ),
          ChatMessage(
            id: 'm2',
            sender: MessageSender.user,
            content: 'Comment réagis-tu quand je t’envoie un message ?',
            timestamp: now.subtract(const Duration(minutes: 5)),
            isDemo: true,
            providerLabel: 'Utilisateur',
          ),
          ChatMessage(
            id: 'm3',
            sender: MessageSender.assistant,
            content:
                '[Réponse de démonstration]\n'
                'À chaque envoi, mes stabilisateurs s’animent et ma visière '
                'émet une impulsion violet néon, puis je passe en mode '
                'réflexion avant d’afficher mon égaliseur vocal pour répondre.',
            timestamp: now.subtract(const Duration(minutes: 4)),
            isDemo: true,
            providerLabel: 'Démo locale',
          ),
        ],
      ),
      Conversation(
        id: 'demo-windows-companion',
        title: 'Compagnon de bureau Windows',
        topicTag: 'Démo • Windows',
        updatedAt: now.subtract(const Duration(hours: 2)),
        isDemo: true,
        messages: [
          ChatMessage(
            id: 'w1',
            sender: MessageSender.user,
            content: 'À quoi sert le mode compagnon compact sur Windows ?',
            timestamp: now.subtract(const Duration(hours: 2, minutes: 4)),
            isDemo: true,
            providerLabel: 'Utilisateur',
          ),
          ChatMessage(
            id: 'w2',
            sender: MessageSender.assistant,
            content:
                '[Réponse de démonstration]\n'
                'Il réduit l’espace principal en une mini-fenêtre dédiée à Nyx '
                'que vous pouvez déplacer sur le bureau et garder au premier '
                'plan au-dessus de vos fenêtres Windows 10/11.',
            timestamp: now.subtract(const Duration(hours: 2)),
            isDemo: true,
            providerLabel: 'Démo locale',
          ),
        ],
      ),
      Conversation(
        id: 'demo-groq-prep',
        title: 'Architecture Groq (Phase 2)',
        topicTag: 'Démo • Architecture',
        updatedAt: now.subtract(const Duration(days: 1)),
        isDemo: true,
        messages: [
          ChatMessage(
            id: 'g1',
            sender: MessageSender.user,
            content: 'Quel fournisseur d’IA sera connecté plus tard ?',
            timestamp: now.subtract(const Duration(days: 1, minutes: 3)),
            isDemo: true,
            providerLabel: 'Utilisateur',
          ),
          ChatMessage(
            id: 'g2',
            sender: MessageSender.assistant,
            content:
                '[Réponse de démonstration]\n'
                'Seule l’API Groq est prévue dans le contrat `AiProviderService`. '
                'Aucune autre plateforme (OpenAI, Anthropic, etc.) n’est '
                'intégrée, et l’API Groq reste volontairement désactivée dans '
                'cette première version.',
            timestamp: now.subtract(const Duration(days: 1)),
            isDemo: true,
            providerLabel: 'Démo locale',
          ),
        ],
      ),
    ];
  }
}
