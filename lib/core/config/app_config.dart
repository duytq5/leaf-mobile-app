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
}
