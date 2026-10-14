import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/error/api_exception.dart';
import 'package:leaf_disease_mobile/features/auth/data/datasources/cognito_auth_data_source.dart';

import '../../../../support/fake_http.dart';

const _settings = CognitoSettings(
  domain: 'leaf-al-1.auth.ap-southeast-2.amazoncognito.com',
  clientId: 'client123',
  redirectUri: 'leafal://auth/callback',
);

const _tokenUrl =
    'POST https://leaf-al-1.auth.ap-southeast-2.amazoncognito.com/oauth2/token';

void main() {
  group('authorizeUrl', () {
    test('asks for a code with PKCE S256 and the app scopes', () {
      final url = CognitoAuthDataSourceImpl(
        Dio(),
        _settings,
      ).authorizeUrl(state: 'st', challenge: 'ch');

      expect(url.host, 'leaf-al-1.auth.ap-southeast-2.amazoncognito.com');
      expect(url.path, '/oauth2/authorize');
      expect(url.queryParameters, {
        'response_type': 'code',
        'client_id': 'client123',
        'redirect_uri': 'leafal://auth/callback',
        'scope': 'openid email profile',
        'state': 'st',
        'code_challenge': 'ch',
        'code_challenge_method': 'S256',
      });
    });

    test('names the identity provider when the build sets one', () {
      final url = CognitoAuthDataSourceImpl(
        Dio(),
        const CognitoSettings(
          domain: 'd.example',
          clientId: 'c',
          redirectUri: 'leafal://auth/callback',
          identityProvider: 'Google',
        ),
      ).authorizeUrl(state: 's', challenge: 'c');

      expect(url.queryParameters['identity_provider'], 'Google');
    });
  });

  group('the token endpoint', () {
    test('exchangeCode posts the code and the verifier as a form', () async {
      final adapter = FakeHttpAdapter({
        _tokenUrl: FakeResponse.json(200, {
          'access_token': 'at',
          'id_token': 'it',
          'refresh_token': 'rt',
          'expires_in': 3600,
          'token_type': 'Bearer',
        }),
      });
      final source = CognitoAuthDataSourceImpl(
        Dio()..httpClientAdapter = adapter,
        _settings,
      );

      final tokens = await source.exchangeCode(code: 'abc', verifier: 'ver');

      expect(tokens.accessToken, 'at');
      expect(tokens.refreshToken, 'rt');
      expect(tokens.expiresIn, const Duration(hours: 1));
      expect(
        adapter.requests.single.contentType,
        'application/x-www-form-urlencoded',
      );
      expect(Uri.splitQueryString(utf8.decode(adapter.bodies.single)), {
        'grant_type': 'authorization_code',
        'client_id': 'client123',
        'code': 'abc',
        'redirect_uri': 'leafal://auth/callback',
        'code_verifier': 'ver',
      });
    });

    test('refresh posts the refresh token; Cognito sends no new one', () async {
      final adapter = FakeHttpAdapter({
        _tokenUrl: FakeResponse.json(200, {
          'access_token': 'at2',
          'id_token': 'it2',
          'expires_in': 3600,
          'token_type': 'Bearer',
        }),
      });
      final source = CognitoAuthDataSourceImpl(
        Dio()..httpClientAdapter = adapter,
        _settings,
      );

      final tokens = await source.refresh('rt');

      expect(tokens.accessToken, 'at2');
      expect(tokens.refreshToken, isNull);
      expect(Uri.splitQueryString(utf8.decode(adapter.bodies.single)), {
        'grant_type': 'refresh_token',
        'client_id': 'client123',
        'refresh_token': 'rt',
      });
    });

    test('a refused grant is an ApiException with the OAuth error', () async {
      final adapter = FakeHttpAdapter({
        _tokenUrl: FakeResponse.json(400, {'error': 'invalid_grant'}),
      });
      final source = CognitoAuthDataSourceImpl(
        Dio()..httpClientAdapter = adapter,
        _settings,
      );

      await expectLater(
        source.refresh('old'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 400)
              .having((e) => e.code, 'code', 'invalid_grant'),
        ),
      );
    });
  });
}
