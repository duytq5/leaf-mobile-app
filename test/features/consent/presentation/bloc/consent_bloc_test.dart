import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/core/usecase/usecase.dart';
import 'package:leaf_disease_mobile/features/consent/domain/entities/consent_record.dart';
import 'package:leaf_disease_mobile/features/consent/domain/usecases/get_consent.dart';
import 'package:leaf_disease_mobile/features/consent/domain/usecases/save_consent.dart';
import 'package:leaf_disease_mobile/features/consent/presentation/bloc/consent_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockGetConsent extends Mock implements GetConsent {}

class MockSaveConsent extends Mock implements SaveConsent {}

void main() {
  late MockGetConsent getConsent;
  late MockSaveConsent saveConsent;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(ConsentRecord.none);
  });

  setUp(() {
    getConsent = MockGetConsent();
    saveConsent = MockSaveConsent();
  });

  ConsentBloc build() =>
      ConsentBloc(getConsent: getConsent, saveConsent: saveConsent);

  blocTest<ConsentBloc, ConsentState>(
    'a stored agreement goes straight to accepted',
    setUp: () => when(() => getConsent(any())).thenAnswer(
      (_) async => Right(ConsentRecord(agreed: true, agreedAt: DateTime(2026))),
    ),
    build: build,
    act: (bloc) => bloc.add(const ConsentRequested()),
    expect: () => const [
      ConsentState(status: ConsentStatus.loading),
      ConsentState(status: ConsentStatus.accepted, checked: true),
    ],
  );

  blocTest<ConsentBloc, ConsentState>(
    'no stored agreement shows the screen',
    setUp: () => when(() => getConsent(any()))
        .thenAnswer((_) async => const Right(ConsentRecord.none)),
    build: build,
    act: (bloc) => bloc.add(const ConsentRequested()),
    expect: () => const [
      ConsentState(status: ConsentStatus.loading),
      ConsentState(status: ConsentStatus.ready),
    ],
  );

  blocTest<ConsentBloc, ConsentState>(
    'a read failure shows the failure',
    setUp: () => when(() => getConsent(any()))
        .thenAnswer((_) async => const Left(CacheFailure('no store'))),
    build: build,
    act: (bloc) => bloc.add(const ConsentRequested()),
    expect: () => const [
      ConsentState(status: ConsentStatus.loading),
      ConsentState(
        status: ConsentStatus.failure,
        failure: CacheFailure('no store'),
      ),
    ],
  );

  blocTest<ConsentBloc, ConsentState>(
    'the checkbox changes only the checked flag',
    build: build,
    act: (bloc) => bloc
      ..add(const ConsentToggled(true))
      ..add(const ConsentToggled(false)),
    expect: () => const [
      ConsentState(checked: true),
      ConsentState(checked: false),
    ],
  );

  blocTest<ConsentBloc, ConsentState>(
    'an accept with a clear checkbox does nothing',
    build: build,
    act: (bloc) => bloc.add(const ConsentAccepted()),
    expect: () => const <ConsentState>[],
    verify: (_) => verifyNever(() => saveConsent(any())),
  );

  blocTest<ConsentBloc, ConsentState>(
    'an accept with a ticked checkbox stores the record',
    setUp: () =>
        when(() => saveConsent(any())).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => const ConsentState(status: ConsentStatus.ready, checked: true),
    act: (bloc) => bloc.add(const ConsentAccepted()),
    expect: () => const [
      ConsentState(status: ConsentStatus.loading, checked: true),
      ConsentState(status: ConsentStatus.accepted, checked: true),
    ],
    verify: (_) {
      final record = verify(() => saveConsent(captureAny())).captured.single
          as ConsentRecord;
      expect(record.agreed, isTrue);
      expect(record.agreedAt, isNotNull);
    },
  );

  blocTest<ConsentBloc, ConsentState>(
    'a write failure shows the failure',
    setUp: () => when(() => saveConsent(any()))
        .thenAnswer((_) async => const Left(CacheFailure('full disk'))),
    build: build,
    seed: () => const ConsentState(status: ConsentStatus.ready, checked: true),
    act: (bloc) => bloc.add(const ConsentAccepted()),
    expect: () => const [
      ConsentState(status: ConsentStatus.loading, checked: true),
      ConsentState(
        status: ConsentStatus.failure,
        checked: true,
        failure: CacheFailure('full disk'),
      ),
    ],
  );
}
