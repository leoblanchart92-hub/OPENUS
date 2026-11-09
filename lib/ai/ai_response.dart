/// Standardized response returned by an [AiProviderService].
class AiResponse {
  const AiResponse({
    required this.content,
    required this.modelUsed,
    required this.providerId,
    required this.isSimulated,
    required this.latency,
  });

  final String content;
  final String modelUsed;
  final String providerId;
  final bool isSimulated;
  final Duration latency;
}
