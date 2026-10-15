import 'package:dio/dio.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/network/dio_errors.dart';
import '../../domain/entities/pending_capture.dart';

/// The answer of `POST /v1/captures`.
class CaptureAnswer {
  const CaptureAnswer({
    required this.alreadyExists,
    this.uploadUrl,
    this.uploadHeaders = const {},
  });

  /// The platform has this image already; nothing to upload.
  final bool alreadyExists;

  /// The presigned S3 PUT, valid 15 minutes.
  final Uri? uploadUrl;

  /// The headers the PUT must send, because the URL signs them.
  final Map<String, String> uploadHeaders;
}

/// Sends a capture to the Edge API and its image straight to S3.
///
/// Every method throws an [ApiException] when a request fails.
abstract class CapturesRemoteDataSource {
  Future<CaptureAnswer> create({
    required String token,
    required PendingCapture capture,
  });

  Future<void> upload({
    required Uri url,
    required Map<String, String> headers,
    required List<int> bytes,
  });
}

class CapturesRemoteDataSourceImpl implements CapturesRemoteDataSource {
  CapturesRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<CaptureAnswer> create({
    required String token,
    required PendingCapture capture,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/captures',
        data: capture.toRequestJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = response.data!;
      final upload = body['upload'] as Map<String, dynamic>?;
      return CaptureAnswer(
        alreadyExists: body['status'] == 'already_exists',
        uploadUrl: upload == null ? null : Uri.parse(upload['url'] as String),
        uploadHeaders: {
          for (final entry
              in ((upload?['headers'] as Map<String, dynamic>?) ?? const {})
                  .entries)
            entry.key: entry.value as String,
        },
      );
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }

  @override
  Future<void> upload({
    required Uri url,
    required Map<String, String> headers,
    required List<int> bytes,
  }) async {
    try {
      await _dio.putUri<void>(
        url,
        data: Stream.value(bytes),
        options: Options(
          // The signed headers only; the bearer token never goes to S3.
          headers: {
            ...headers,
            if (!headers.keys.any(
              (k) => k.toLowerCase() == Headers.contentLengthHeader,
            ))
              Headers.contentLengthHeader: bytes.length,
          },
          contentType: headers['Content-Type'],
        ),
      );
    } on DioException catch (error) {
      throw apiExceptionFrom(error);
    }
  }
}
