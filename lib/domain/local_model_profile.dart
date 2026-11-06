/// A conservative, real Ollama model recommendation for low-memory machines.
///
/// The published artifact size is NOT a measurement of process RAM. The runtime
/// also needs KV cache, compute buffers and allocator overhead. OPENUS therefore
/// limits context/batch/output and unloads the model after each reply, but does
/// not claim a hard operating-system memory cap.
abstract final class LocalModelProfile {
  static const recommendedModel = 'qwen3:0.6b-q4_K_M';
  static const displayName = 'Qwen3 0,6B · Q4_K_M';
  static const publishedArtifactLabel = 'environ 523 Mo';
  static const targetEngineRamGiB = 4;
  static const contextTokens = 2048;
  static const outputTokens = 512;
  static const batchTokens = 128;
  static const conversationMessages = 8;
  static const pullCommand = 'ollama pull $recommendedModel';

  /// Leave headroom below the 4 GiB target for runtime buffers. This rejects
  /// known oversized artifacts in light mode; it is not a RAM guarantee.
  static const maxArtifactBytes = 2 * 1024 * 1024 * 1024;

  static bool isRecommended(String model) => model.trim() == recommendedModel;
  static bool supportsThinkingSwitch(String model) =>
      model.trim().toLowerCase().startsWith('qwen3:');
}
