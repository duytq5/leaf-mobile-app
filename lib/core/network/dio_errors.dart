import 'package:dio/dio.dart';

import '../error/api_exception.dart';

/// Turns a failed request into an [ApiException].
///
/// The platform answers an error with `{"error": {"code", "message"}}`. A
/// response without that body, such as an S3 or a throttling error, keeps only
/// its status.
ApiException apiExceptionFrom(DioException error) {
  final response = error.response;
  if (response == null) {
    return ApiException.offline(error.message ?? 'the server does not answer');
  }

  String? code;
  String? message;
  final body = response.data;
  if (body is Map && body['error'] is Map) {
    code = body['error']['code'] as String?;
    message = body['error']['message'] as String?;
  }

  final retry = int.tryParse(response.headers.value('retry-after') ?? '');
  return ApiException(
    status: response.statusCode,
    code: code,
    message: message ?? 'the server answers ${response.statusCode}',
    retryAfter: retry == null ? null : Duration(seconds: retry),
  );
}
