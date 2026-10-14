/// The addresses the app talks to.
///
/// A build can change each value with `--dart-define`, for example
/// `fvm flutter run --dart-define=API_BASE_URL=https://example.org`.
abstract final class AppConfig {
  /// The Edge API of the platform (API Gateway HTTP API).
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://0vxi4ulyok.execute-api.ap-southeast-2.amazonaws.com',
  );

  /// The Cognito managed login host of the user pool.
  static const cognitoDomain = String.fromEnvironment(
    'COGNITO_DOMAIN',
    defaultValue: 'leaf-al-869935094432.auth.ap-southeast-2.amazoncognito.com',
  );

  /// The public `mobile` app client (CDK output `MobileClientId`). Without it
  /// the app still scans, but cannot sign in to send photos.
  static const cognitoClientId = String.fromEnvironment('COGNITO_CLIENT_ID');

  /// `Google` once the platform has Google sign-in; empty shows the Cognito
  /// login page.
  static const cognitoIdentityProvider = String.fromEnvironment(
    'COGNITO_IDENTITY_PROVIDER',
  );

  /// The sign-in redirect the `mobile` client allows (CDK context
  /// `mobileCallbackUrls`).
  static const cognitoRedirectUri = 'leafal://auth/callback';
}
