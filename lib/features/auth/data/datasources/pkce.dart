import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A PKCE pair (RFC 7636) for one sign-in.
///
/// The app sends [challenge] with the authorize request and [verifier] with
/// the code exchange, so a stolen code is useless without the app.
class Pkce {
  const Pkce._(this.verifier, this.challenge);

  factory Pkce.generate() => Pkce.fromVerifier(_random(64));

  factory Pkce.fromVerifier(String verifier) => Pkce._(
    verifier,
    base64Url
        .encode(sha256.convert(ascii.encode(verifier)).bytes)
        .replaceAll('=', ''),
  );

  final String verifier;

  /// The unpadded base64url SHA-256 of [verifier] (method S256).
  final String challenge;

  /// A random `state` value, which the callback must echo.
  static String state() => _random(32);

  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  static String _random(int length) {
    final random = Random.secure();
    return String.fromCharCodes([
      for (var i = 0; i < length; i++)
        _alphabet.codeUnitAt(random.nextInt(_alphabet.length)),
    ]);
  }
}
