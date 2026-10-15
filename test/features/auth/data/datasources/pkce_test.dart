import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/features/auth/data/datasources/pkce.dart';

void main() {
  test('the verifier is 64 URL-safe characters', () {
    final pkce = Pkce.generate();

    expect(pkce.verifier, hasLength(64));
    expect(RegExp(r'^[A-Za-z0-9\-._~]+$').hasMatch(pkce.verifier), isTrue);
  });

  test('the challenge is the unpadded base64url SHA-256 of the verifier', () {
    final pkce = Pkce.generate();
    final expected = base64Url
        .encode(sha256.convert(ascii.encode(pkce.verifier)).bytes)
        .replaceAll('=', '');

    expect(pkce.challenge, expected);
  });

  test('matches the example of RFC 7636 appendix B', () {
    const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';

    expect(
      Pkce.fromVerifier(verifier).challenge,
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
  });

  test('two pairs differ', () {
    expect(Pkce.generate().verifier, isNot(Pkce.generate().verifier));
    expect(Pkce.state(), isNot(Pkce.state()));
  });
}
