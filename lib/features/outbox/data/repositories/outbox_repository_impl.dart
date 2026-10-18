import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image/image.dart' as img;

import '../../../../core/error/api_exception.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../models/domain/entities/leaf_model.dart';
import '../../../scan/domain/entities/scan_result.dart';
import '../../domain/entities/pending_capture.dart';
import '../../domain/repositories/outbox_repository.dart';
import '../datasources/captures_remote_data_source.dart';
import '../datasources/connectivity_data_source.dart';
import '../datasources/outbox_local_data_source.dart';

class OutboxRepositoryImpl implements OutboxRepository {
  OutboxRepositoryImpl({
    required this.local,
    required this.remote,
    required this.auth,
    this.connectivity,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The largest image the platform takes (`MAX_UPLOAD_BYTES`).
  static const maxBytes = 10 * 1024 * 1024;

  final OutboxLocalDataSource local;
  final CapturesRemoteDataSource remote;
  final AuthRepository auth;
  final ConnectivityDataSource? connectivity;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, Unit>> enqueue(
    ScanResult result,
    LeafModel model,
  ) async {
    final dataset = model.datasetName;
    final version = model.manifest.modelVersionRef;
    if (dataset == null || version == null) {
      return const Left(
        ModelFailure('a bundled model cannot send photos to the platform'),
      );
    }

    try {
      final (bytes, contentType) = _uploadable(result.imageBytes);
      if (bytes.length > maxBytes) {
        return const Left(
          ImageFailure(
            'the photo is larger than 10 MB',
            code: FailureCode.photoTooLarge,
          ),
        );
      }
      await local.save(
        PendingCapture(
          captureId: newCaptureId(),
          dataset: dataset,
          capturedAt: _clock().toUtc(),
          modelVersion: version,
          probs: {for (final s in result.scores) s.code: s.probability},
          sha256: sha256.convert(bytes).toString(),
          contentType: contentType,
          size: bytes.length,
          imagePath: '',
        ),
        bytes,
      );
      return const Right(unit);
    } catch (error) {
      return Left(CacheFailure('the app cannot store the photo: $error'));
    }
  }

  @override
  Future<Either<Failure, OutboxReport>> send() async {
    final waiting = await local.list();
    if (waiting.isEmpty) return const Right(OutboxReport());

    final token = await auth.accessToken();
    if (token.isLeft()) {
      return Left(token.getLeft().toNullable()!);
    }

    var sent = 0;
    var dropped = 0;
    for (final capture in waiting) {
      try {
        final answer = await remote.create(
          token: token.getRight().toNullable()!,
          capture: capture,
        );
        if (!answer.alreadyExists) {
          await remote.upload(
            url: answer.uploadUrl!,
            headers: answer.uploadHeaders,
            bytes: await local.readImage(capture),
          );
        }
        await local.delete(capture.captureId);
        sent++;
      } on ApiException catch (error) {
        final status = error.status;
        if (status == 429) {
          return Left(
            QuotaFailure(
              'the daily photo limit is reached',
              retryAfter: error.retryAfter,
            ),
          );
        }
        if (status == 401 || status == 403) {
          return const Left(
            AuthFailure(
              'sign in again to send photos',
              code: FailureCode.signInExpired,
            ),
          );
        }
        if (status == 400 || status == 404 || status == 409) {
          // The platform will never take this body, so it leaves the outbox.
          await local.delete(capture.captureId);
          dropped++;
          continue;
        }
        // Offline, a server error or an expired upload link: try again later.
        break;
      }
    }
    return Right(
      OutboxReport(
        sent: sent,
        dropped: dropped,
        left: waiting.length - sent - dropped,
      ),
    );
  }

  @override
  Future<int> pendingCount() async => (await local.list()).length;

  @override
  Stream<void> get onlineAgain =>
      connectivity?.onlineAgain ?? const Stream.empty();

  /// The platform takes JPEG or PNG. Anything else, such as HEIC from an
  /// older phone, is stored as a JPEG.
  (Uint8List, String) _uploadable(Uint8List bytes) {
    if (bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return (bytes, 'image/jpeg');
    }
    if (bytes.length > 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return (bytes, 'image/png');
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('the photo does not decode');
    }
    return (
      Uint8List.fromList(img.encodeJpg(decoded, quality: 90)),
      'image/jpeg',
    );
  }
}
