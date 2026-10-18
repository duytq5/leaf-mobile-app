import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image/image.dart' as img;
import 'package:leaf_disease_mobile/core/error/api_exception.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:leaf_disease_mobile/features/outbox/data/datasources/captures_remote_data_source.dart';
import 'package:leaf_disease_mobile/features/outbox/data/datasources/outbox_local_data_source.dart';
import 'package:leaf_disease_mobile/features/outbox/data/repositories/outbox_repository_impl.dart';
import 'package:leaf_disease_mobile/features/outbox/domain/entities/pending_capture.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/class_score.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/scan_result.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/uncertainty.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/model_fixtures.dart';
import '../../../../support/outbox_fixtures.dart';

class MockLocal extends Mock implements OutboxLocalDataSource {}

class MockRemote extends Mock implements CapturesRemoteDataSource {}

class MockAuth extends Mock implements AuthRepository {}

final _jpeg = Uint8List.fromList(img.encodeJpg(img.Image(width: 4, height: 4)));

ScanResult _scan(Uint8List bytes) => ScanResult(
  imageBytes: bytes,
  scores: const [
    ClassScore('Rust', 0.75, code: 'rust'),
    ClassScore('Healthy', 0.25, code: 'healthy'),
  ],
  uncertainty: Uncertainty.fromProbabilities(const [0.75, 0.25]),
  latency: const Duration(milliseconds: 100),
  modelId: 'rocole',
  modelVersion: '3',
);

void main() {
  late MockLocal local;
  late MockRemote remote;
  late MockAuth auth;
  late OutboxRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(pendingCapture());
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(Uri());
  });

  setUp(() {
    local = MockLocal();
    remote = MockRemote();
    auth = MockAuth();
    repository = OutboxRepositoryImpl(
      local: local,
      remote: remote,
      auth: auth,
      clock: () => DateTime.utc(2026, 10, 14, 8, 12),
    );
    when(
      () => local.save(any(), any()),
    ).thenAnswer((call) async => call.positionalArguments[0] as PendingCapture);
    when(() => local.delete(any())).thenAnswer((_) async {});
    when(() => auth.accessToken()).thenAnswer((_) async => const Right('at'));
  });

  group('enqueue', () {
    test('stores the prediction keyed by class code, and the JPEG', () async {
      final result = await repository.enqueue(_scan(_jpeg), releasedModel);

      expect(result.isRight(), isTrue);
      final call = verify(() => local.save(captureAny(), captureAny()));
      final capture = call.captured[0] as PendingCapture;
      expect(capture.dataset, 'rocole');
      expect(capture.modelVersion, 'leaf-disease-rocole/3');
      expect(capture.probs, {'rust': 0.75, 'healthy': 0.25});
      expect(capture.contentType, 'image/jpeg');
      expect(capture.size, _jpeg.length);
      expect(capture.sha256, sha256.convert(_jpeg).toString());
      expect(capture.capturedAt, DateTime.utc(2026, 10, 14, 8, 12));
      expect(call.captured[1], _jpeg);
    });

    test('an image that is not JPEG or PNG is stored as a JPEG', () async {
      final bmp = Uint8List.fromList(
        img.encodeBmp(img.Image(width: 4, height: 4)),
      );

      await repository.enqueue(_scan(bmp), releasedModel);

      final call = verify(() => local.save(captureAny(), captureAny()));
      final bytes = call.captured[1] as Uint8List;
      expect(bytes.sublist(0, 2), [0xFF, 0xD8]);
      expect((call.captured[0] as PendingCapture).contentType, 'image/jpeg');
    });

    test('a bundled model cannot send, so nothing is stored', () async {
      final result = await repository.enqueue(_scan(_jpeg), coffeeModel);

      expect(result.getLeft().toNullable(), isA<ModelFailure>());
      verifyNever(() => local.save(any(), any()));
    });
  });

  group('send', () {
    setUp(() {
      when(() => local.list()).thenAnswer(
        (_) async => [pendingCapture(id: 'a'), pendingCapture(id: 'b')],
      );
      when(() => local.readImage(any())).thenAnswer((_) async => _jpeg);
    });

    void givenAnswer(CaptureAnswer answer) {
      when(
        () => remote.create(
          token: any(named: 'token'),
          capture: any(named: 'capture'),
        ),
      ).thenAnswer((_) async => answer);
    }

    test('uploads each capture and empties the outbox', () async {
      givenAnswer(
        CaptureAnswer(
          alreadyExists: false,
          uploadUrl: Uri.parse('https://s3.test/put'),
          uploadHeaders: const {'Content-Type': 'image/jpeg'},
        ),
      );
      when(
        () => remote.upload(
          url: any(named: 'url'),
          headers: any(named: 'headers'),
          bytes: any(named: 'bytes'),
        ),
      ).thenAnswer((_) async {});

      final report = (await repository.send()).getRight().toNullable()!;

      expect(report.sent, 2);
      expect(report.left, 0);
      verify(() => local.delete('a')).called(1);
      verify(() => local.delete('b')).called(1);
    });

    test('already_exists needs no upload', () async {
      givenAnswer(const CaptureAnswer(alreadyExists: true));

      final report = (await repository.send()).getRight().toNullable()!;

      expect(report.sent, 2);
      verifyNever(
        () => remote.upload(
          url: any(named: 'url'),
          headers: any(named: 'headers'),
          bytes: any(named: 'bytes'),
        ),
      );
    });

    test('offline stops and keeps every capture', () async {
      when(
        () => remote.create(
          token: any(named: 'token'),
          capture: any(named: 'capture'),
        ),
      ).thenThrow(const ApiException.offline('no network'));

      final report = (await repository.send()).getRight().toNullable()!;

      expect(report.sent, 0);
      expect(report.left, 2);
      verifyNever(() => local.delete(any()));
    });

    test('the daily limit stops and says so', () async {
      when(
        () => remote.create(
          token: any(named: 'token'),
          capture: any(named: 'capture'),
        ),
      ).thenThrow(
        const ApiException(status: 429, code: 'quota_exceeded', message: 'x'),
      );

      final result = await repository.send();

      expect(result.getLeft().toNullable(), isA<QuotaFailure>());
      verifyNever(() => local.delete(any()));
    });

    test('a capture the platform refuses is dropped, the next goes', () async {
      var calls = 0;
      when(
        () => remote.create(
          token: any(named: 'token'),
          capture: any(named: 'capture'),
        ),
      ).thenAnswer((_) async {
        if (calls++ == 0) {
          throw const ApiException(
            status: 400,
            code: 'invalid_request',
            message: 'x',
          );
        }
        return const CaptureAnswer(alreadyExists: true);
      });

      final report = (await repository.send()).getRight().toNullable()!;

      expect(report.sent, 1);
      expect(report.dropped, 1);
      verify(() => local.delete('a')).called(1);
      verify(() => local.delete('b')).called(1);
    });

    test('a refused token stops with an AuthFailure', () async {
      when(
        () => remote.create(
          token: any(named: 'token'),
          capture: any(named: 'capture'),
        ),
      ).thenThrow(
        const ApiException(status: 403, code: 'forbidden', message: 'x'),
      );

      final result = await repository.send();

      expect(
        result.getLeft().toNullable(),
        isA<AuthFailure>().having((f) => f.code, 'code', FailureCode.signInExpired),
      );
      verifyNever(() => local.delete(any()));
    });

    test('signed out sends nothing', () async {
      when(() => auth.accessToken())
          .thenAnswer((_) async => const Left(AuthFailure('sign in')));

      final result = await repository.send();

      expect(result.getLeft().toNullable(), isA<AuthFailure>());
      verifyNever(
        () => remote.create(
          token: any(named: 'token'),
          capture: any(named: 'capture'),
        ),
      );
    });

    test('an empty outbox asks for no token', () async {
      when(() => local.list()).thenAnswer((_) async => []);

      final report = (await repository.send()).getRight().toNullable()!;

      expect(report.left, 0);
      verifyNever(() => auth.accessToken());
    });
  });
}
