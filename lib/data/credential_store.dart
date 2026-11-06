import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/ai.dart';

abstract interface class CredentialStore {
  Future<String?> read(CloudProvider provider);
  Future<void> save(CloudProvider provider, String key);
  Future<void> delete(CloudProvider provider);
}

/// Android Keystore-backed encrypted preferences; Windows Credential Manager/DPAPI.
/// Failure is surfaced to the UI. There is NO plaintext or in-memory-only fallback
/// that would misleadingly display a key as permanently saved.
class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(),
  );
  final FlutterSecureStorage _storage;
  String _name(CloudProvider provider) => 'openus.api.${provider.name}.v1';

  @override
  Future<String?> read(CloudProvider provider) async {
    try {
      final value = await _storage.read(key: _name(provider));
      return value == null || value.trim().isEmpty ? null : value.trim();
    } catch (_) {
      throw const CredentialFailure();
    }
  }

  @override
  Future<void> save(CloudProvider provider, String key) async {
    if (key.trim().isEmpty) throw ArgumentError('Empty API key');
    try { await _storage.write(key: _name(provider), value: key.trim()); }
    catch (_) { throw const CredentialFailure(); }
  }

  @override
  Future<void> delete(CloudProvider provider) async {
    try { await _storage.delete(key: _name(provider)); }
    catch (_) { throw const CredentialFailure(); }
  }
}

class CredentialFailure implements Exception {
  const CredentialFailure();
  @override
  String toString() => 'Stockage sécurisé indisponible. La clé n’a pas été enregistrée en clair. Vérifiez le trousseau de votre appareil.';
}
