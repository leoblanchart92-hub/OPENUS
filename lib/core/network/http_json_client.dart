import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/ai.dart';

/// Owned-per-request clients make cancellation and concurrent probes independent.
class HttpJsonClient {
  const HttpJsonClient(this._clientFactory);
  final http.Client Function() _clientFactory;

  Future<Map<String, dynamic>> request(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    Map<String, Object?>? body,
    Duration timeout = const Duration(seconds: 10),
    AiCancelToken? cancelToken,
  }) async {
    final client = _clientFactory();
    void cancel() => client.close();
    cancelToken?.addListener(cancel);
    try {
      cancelToken?.throwIfCancelled();
      final request = http.Request(method, uri)
        ..headers.addAll({'accept': 'application/json', ...headers})
        ..persistentConnection = false;
      if (body != null) {
        request.headers['content-type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final streamed = await client
          .send(request)
          .timeout(
            timeout,
            onTimeout: () {
              client.close();
              throw const AiException(
                'Le serveur n’a pas répondu à temps. Vérifiez le moteur puis réessayez.',
              );
            },
          );
      final response = await http.Response.fromStream(streamed).timeout(
        timeout,
        onTimeout: () {
          client.close();
          throw const AiException(
            'Réponse du serveur incomplète ou trop lente.',
          );
        },
      );
      cancelToken?.throwIfCancelled();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Never include response bodies, request headers, keys or query strings.
        final message = switch (response.statusCode) {
          401 || 403 =>
            'Accès refusé (HTTP ${response.statusCode}). Vérifiez la clé et ses permissions.',
          404 =>
            'Endpoint ou modèle introuvable (HTTP 404). Vérifiez la configuration.',
          429 =>
            'Limite du fournisseur atteinte (HTTP 429). Réessayez plus tard ou vérifiez votre quota.',
          _ => 'Le moteur a renvoyé une erreur HTTP ${response.statusCode}.',
        };
        throw AiException(message);
      }
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      } on FormatException {
        /* normalized below */
      }
      throw const AiException(
        'Le serveur a renvoyé une réponse JSON invalide.',
      );
    } on AiException {
      rethrow;
    } on http.ClientException {
      cancelToken?.throwIfCancelled();
      throw const AiException(
        'Connexion au moteur impossible. Vérifiez le serveur, le réseau et les autorisations Android.',
      );
    } on TimeoutException {
      throw const AiException(
        'Délai d’attente dépassé. Le moteur n’a pas répondu.',
      );
    } on FormatException {
      throw const AiException('Réponse du moteur invalide.');
    } catch (_) {
      cancelToken?.throwIfCancelled();
      // Do not leak exception details that could contain a credential or payload.
      throw const AiException(
        'La requête a échoué. Vérifiez la configuration du moteur.',
      );
    } finally {
      cancelToken?.removeListener(cancel);
      client.close();
    }
  }
}

List<String> modelIds(Map<String, dynamic> json, String key) {
  final entries = json[key];
  if (entries is! List) {
    throw const AiException('Liste de modèles absente ou invalide.');
  }
  return entries
      .whereType<Map<String, dynamic>>()
      .map((m) => m['id'] ?? m['name'])
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
}
