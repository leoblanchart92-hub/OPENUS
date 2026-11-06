import 'dart:math';

/// Local identifiers; no account, device fingerprint or network service involved.
String newId() {
  final random = Random.secure();
  final suffix = List.generate(
    8,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '${DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(16)}-$suffix';
}
