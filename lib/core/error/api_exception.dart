/// Thrown by a remote data source when a request fails.
///
/// A repository catches it and returns a failure, so it never reaches a
/// screen.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.status,
    this.code,
    this.retryAfter,
  });

  /// The request did not reach the server: no network, or a timeout.
  const ApiException.offline(this.message)
    : status = null,
      code = 'offline',
      retryAfter = null;

  /// The HTTP status. It is null when the request never reached the server.
  final int? status;

  /// The `error.code` of the platform's error body, for example
  /// `quota_exceeded`.
  final String? code;

  final String message;

  /// The `Retry-After` header of a 429, when the server sent one.
  final Duration? retryAfter;

  bool get offline => status == null;

  @override
  String toString() => 'ApiException($status, $code): $message';
}
