import 'package:dio/dio.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/dio_errors.dart';

/// The Cognito app client the app signs in with.
class CognitoSettings {
  const CognitoSettings({
    required this.domain,
    required this.clientId,
    required this.redirectUri,
    this.identityProvider,
  });

  /// The managed login host, for example
  /// `leaf-al-123.auth.ap-southeast-2.amazoncognito.com`.
  final String domain;

  /// The public `mobile` app client. It has no secret.
  final String clientId;

  /// The sign-in redirect the app client allows.
  final String redirectUri;

  /// `Google` sends the user straight to Google. Null shows the Cognito login
  /// page, for a build made before Google sign-in is set up.
  final String? identityProvider;

  bool get configured => domain.isNotEmpty && clientId.isNotEmpty;

  /// The scheme of [redirectUri], which the browser step listens for.
  String get callbackScheme => Uri.parse(redirectUri).scheme;
}

/// The tokens of one answer of the token endpoint.
class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.expiresIn,
    this.refreshToken,
  });

  final String accessToken;
  final Duration expiresIn;

  /// Sent on the code exchange only. A refresh keeps the old one.
  final String? refreshToken;
}

/// The OAuth 2.0 endpoints of the Cognito managed login: authorization code
/// with PKCE, and refresh.
abstract class CognitoAuthDataSource {
  Uri authorizeUrl({required String state, required String challenge});

  Future<TokenResponse> exchangeCode({
    required String code,
    required String verifier,
  });

  Future<TokenResponse> refresh(String refreshToken);
}

class CognitoAuthDataSourceImpl implements CognitoAuthDataSource {
  CognitoAuthDataSourceImpl(this._dio, this.settings);

  final Dio _dio;
  final CognitoSettings settings;

  @override
  Uri authorizeUrl({required String state, required String challenge}) {
    return Uri.https(settings.domain, '/oauth2/authorize', {
      'response_type': 'code',
      'client_id': settings.clientId,
      'redirect_uri': settings.redirectUri,
      'scope': 'openid email profile',
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      if (settings.identityProvider case final idp? when idp.isNotEmpty)
        'identity_provider': idp,
    });
  }

  @override
  Future<TokenResponse> exchangeCode({
    required String code,
    required String verifier,
  }) => _token({
    'grant_type': 'authorization_code',
    'client_id': settings.clientId,
    'code': code,
    'redirect_uri': settings.redirectUri,
    'code_verifier': verifier,
  });

  @override
  Future<TokenResponse> refresh(String refreshToken) => _token({
    'grant_type': 'refresh_token',
    'client_id': settings.clientId,
    'refresh_token': refreshToken,
  });

  Future<TokenResponse> _token(Map<String, String> form) async {
    try {
      final response = await _dio.postUri<Map<String, dynamic>>(
        Uri.https(settings.domain, '/oauth2/token'),
        data: form,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final body = response.data!;
      return TokenResponse(
        accessToken: body['access_token'] as String,
        refreshToken: body['refresh_token'] as String?,
        expiresIn: Duration(seconds: body['expires_in'] as int),
      );
    } on DioException catch (error) {
      // OAuth errors are `{"error": "invalid_grant"}`, not the API's shape.
      final body = error.response?.data;
      if (body is Map && body['error'] is String) {
        throw ApiException(
          status: error.response?.statusCode,
          code: body['error'] as String,
          message: 'the sign-in was refused: ${body['error']}',
        );
      }
      throw apiExceptionFrom(error);
    }
  }
}
