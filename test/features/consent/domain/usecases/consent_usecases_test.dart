import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/core/usecase/usecase.dart';
import 'package:leaf_disease_mobile/features/consent/domain/entities/consent_record.dart';
import 'package:leaf_disease_mobile/features/consent/domain/repositories/consent_repository.dart';
import 'package:leaf_disease_mobile/features/consent/domain/usecases/get_consent.dart';
import 'package:leaf_disease_mobile/features/consent/domain/usecases/save_consent.dart';
import 'package:mocktail/mocktail.dart';

class MockConsentRepository extends Mock implements ConsentRepository {}

void main() {
  late MockConsentRepository repository;

  setUpAll(() {
    registerFallbackValue(ConsentRecord.none);
  });

  setUp(() => repository = MockConsentRepository());

  group('GetConsent', () {
    test('returns the record of the repository', () async {
      final record = ConsentRecord(agreed: true, agreedAt: DateTime(2026, 9, 29));
      when(() => repository.read()).thenAnswer((_) async => Right(record));

      final result = await GetConsent(repository)(const NoParams());

      expect(result.getRight().toNullable(), record);
      verify(() => repository.read()).called(1);
    });

    test('passes a failure through', () async {
      when(() => repository.read())
          .thenAnswer((_) async => const Left(CacheFailure('no store')));

      final result = await GetConsent(repository)(const NoParams());

      expect(result.getLeft().toNullable(), const CacheFailure('no store'));
    });
  });

  group('SaveConsent', () {
    test('gives the record to the repository', () async {
      final record = ConsentRecord(agreed: true, agreedAt: DateTime(2026, 9, 29));
      when(() => repository.write(any())).thenAnswer((_) async => const Right(unit));

      final result = await SaveConsent(repository)(record);

      expect(result.isRight(), isTrue);
      verify(() => repository.write(record)).called(1);
    });

    test('passes a failure through', () async {
      when(() => repository.write(any()))
          .thenAnswer((_) async => const Left(CacheFailure('full disk')));

      final result = await SaveConsent(repository)(ConsentRecord.none);

      expect(result.isLeft(), isTrue);
    });
  });

  group('ConsentRecord', () {
    test('none means the user did not answer', () {
      expect(ConsentRecord.none.agreed, isFalse);
      expect(ConsentRecord.none.agreedAt, isNull);
    });

    test('two records with the same values are equal', () {
      final at = DateTime(2026, 9, 29);
      expect(
        ConsentRecord(agreed: true, agreedAt: at),
        ConsentRecord(agreed: true, agreedAt: at),
      );
    });
  });
}
