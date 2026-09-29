import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/label_correction.dart';
import 'package:leaf_disease_mobile/features/scan/domain/usecases/submit_correction.dart';
import 'package:leaf_disease_mobile/features/scan/presentation/bloc/correction_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/model_fixtures.dart';
import '../../../../support/scan_fixtures.dart';

class MockSubmitCorrection extends Mock implements SubmitCorrection {}

void main() {
  late MockSubmitCorrection submitCorrection;

  setUpAll(() {
    registerFallbackValue(
      LabelCorrection(
        modelId: 'x',
        modelVersion: 'v',
        predictedLabel: 'a',
        correctedLabel: 'b',
        submittedAt: DateTime(2026),
      ),
    );
  });

  setUp(() => submitCorrection = MockSubmitCorrection());

  CorrectionBloc build() => CorrectionBloc(
    submitCorrection: submitCorrection,
    result: coffeeScan(),
    model: coffeeModel,
  );

  test('offers every label of the model and one escape row', () {
    expect(build().choices, [
      'coffee___healthy',
      'coffee___red_spider_mite',
      'coffee___rust',
      LabelCorrection.notSure,
    ]);
  });

  test('offers six labels and the escape row for the durian model', () {
    final bloc = CorrectionBloc(
      submitCorrection: submitCorrection,
      result: coffeeScan(),
      model: durianModel,
    );

    expect(bloc.choices, hasLength(7));
    expect(bloc.choices.last, LabelCorrection.notSure);
  });

  blocTest<CorrectionBloc, CorrectionState>(
    'a choice sets the label',
    build: build,
    act: (bloc) => bloc.add(const CorrectionLabelChosen('coffee___healthy')),
    expect: () => const [CorrectionState(chosen: 'coffee___healthy')],
  );

  blocTest<CorrectionBloc, CorrectionState>(
    'a submit with no choice does nothing',
    build: build,
    act: (bloc) => bloc.add(const CorrectionSubmitted()),
    expect: () => const <CorrectionState>[],
    verify: (_) => verifyNever(() => submitCorrection(any())),
  );

  blocTest<CorrectionBloc, CorrectionState>(
    'a submit stores the correction',
    setUp: () => when(() => submitCorrection(any()))
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => const CorrectionState(chosen: 'coffee___healthy'),
    act: (bloc) => bloc.add(const CorrectionSubmitted()),
    expect: () => const [
      CorrectionState(
        status: CorrectionStatus.saving,
        chosen: 'coffee___healthy',
      ),
      CorrectionState(
        status: CorrectionStatus.saved,
        chosen: 'coffee___healthy',
      ),
    ],
    verify: (_) {
      final saved = verify(() => submitCorrection(captureAny())).captured.single
          as LabelCorrection;
      // The correction carries the label the model gave and the label the
      // person gave. The active learning round needs both.
      expect(saved.predictedLabel, 'coffee___rust');
      expect(saved.correctedLabel, 'coffee___healthy');
      expect(saved.modelId, 'coffee_rocole');
      expect(saved.modelVersion, 'fold-1-best');
    },
  );

  blocTest<CorrectionBloc, CorrectionState>(
    'a store failure shows the message',
    setUp: () => when(() => submitCorrection(any()))
        .thenAnswer((_) async => const Left(CacheFailure('full disk'))),
    build: build,
    seed: () => const CorrectionState(chosen: 'coffee___healthy'),
    act: (bloc) => bloc.add(const CorrectionSubmitted()),
    expect: () => const [
      CorrectionState(
        status: CorrectionStatus.saving,
        chosen: 'coffee___healthy',
      ),
      CorrectionState(
        status: CorrectionStatus.failure,
        chosen: 'coffee___healthy',
        message: 'full disk',
      ),
    ],
  );
}
