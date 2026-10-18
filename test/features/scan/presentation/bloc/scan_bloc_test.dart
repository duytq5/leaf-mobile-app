import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/image_source_kind.dart';
import 'package:leaf_disease_mobile/features/scan/domain/usecases/classify_image.dart';
import 'package:leaf_disease_mobile/features/scan/domain/usecases/pick_image.dart';
import 'package:leaf_disease_mobile/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/model_fixtures.dart';
import '../../../../support/scan_fixtures.dart';

class MockPickImage extends Mock implements PickImage {}

class MockClassifyImage extends Mock implements ClassifyImage {}

void main() {
  late MockPickImage pickImage;
  late MockClassifyImage classifyImage;

  setUpAll(() {
    registerFallbackValue(ImageSourceKind.camera);
    registerFallbackValue(
      ClassifyParams(bytes: Uint8List(0), model: coffeeModel),
    );
  });

  setUp(() {
    pickImage = MockPickImage();
    classifyImage = MockClassifyImage();
  });

  ScanBloc build() =>
      ScanBloc(pickImage: pickImage, classifyImage: classifyImage);

  final result = coffeeScan();

  blocTest<ScanBloc, ScanState>(
    'a good scan goes picking, running, done',
    setUp: () {
      when(() => pickImage(any())).thenAnswer((_) async => Right(scanImageBytes));
      when(() => classifyImage(any())).thenAnswer((_) async => Right(result));
    },
    build: build,
    act: (bloc) => bloc.add(
      ScanImageRequested(source: ImageSourceKind.camera, model: coffeeModel),
    ),
    expect: () => [
      const ScanState(status: ScanStatus.picking),
      const ScanState(status: ScanStatus.running),
      ScanState(status: ScanStatus.done, result: result),
    ],
  );

  blocTest<ScanBloc, ScanState>(
    'a cancelled picker returns to rest with no message',
    setUp: () => when(() => pickImage(any()))
        .thenAnswer((_) async => const Left(ImageFailure('no image'))),
    build: build,
    act: (bloc) => bloc.add(
      ScanImageRequested(source: ImageSourceKind.gallery, model: coffeeModel),
    ),
    expect: () => const [
      ScanState(status: ScanStatus.picking),
      ScanState(),
    ],
    verify: (_) => verifyNever(() => classifyImage(any())),
  );

  blocTest<ScanBloc, ScanState>(
    'a classify failure shows the message',
    setUp: () {
      when(() => pickImage(any())).thenAnswer((_) async => Right(scanImageBytes));
      when(() => classifyImage(any()))
          .thenAnswer((_) async => const Left(ModelFailure('no session')));
    },
    build: build,
    act: (bloc) => bloc.add(
      ScanImageRequested(source: ImageSourceKind.camera, model: coffeeModel),
    ),
    expect: () => const [
      ScanState(status: ScanStatus.picking),
      ScanState(status: ScanStatus.running),
      ScanState(
        status: ScanStatus.failure,
        failure: ModelFailure('no session'),
      ),
    ],
  );

  blocTest<ScanBloc, ScanState>(
    'gives the selected model to the use case',
    setUp: () {
      when(() => pickImage(any())).thenAnswer((_) async => Right(scanImageBytes));
      when(() => classifyImage(any())).thenAnswer((_) async => Right(result));
    },
    build: build,
    act: (bloc) => bloc.add(
      ScanImageRequested(source: ImageSourceKind.camera, model: durianModel),
    ),
    verify: (_) {
      final params =
          verify(() => classifyImage(captureAny())).captured.single
              as ClassifyParams;
      expect(params.model, durianModel);
      expect(params.bytes, scanImageBytes);
    },
  );

  blocTest<ScanBloc, ScanState>(
    'clearing drops the result',
    build: build,
    seed: () => ScanState(status: ScanStatus.done, result: result),
    act: (bloc) => bloc.add(const ScanCleared()),
    expect: () => const [ScanState()],
  );

  test('the state reports that it is busy while it works', () {
    expect(const ScanState(status: ScanStatus.picking).busy, isTrue);
    expect(const ScanState(status: ScanStatus.running).busy, isTrue);
    expect(const ScanState().busy, isFalse);
    expect(const ScanState(status: ScanStatus.done).busy, isFalse);
  });
}
