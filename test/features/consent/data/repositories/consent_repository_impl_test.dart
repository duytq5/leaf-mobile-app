import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/features/consent/data/datasources/consent_local_data_source.dart';
import 'package:leaf_disease_mobile/features/consent/data/models/consent_record_model.dart';
import 'package:leaf_disease_mobile/features/consent/data/repositories/consent_repository_impl.dart';
import 'package:leaf_disease_mobile/features/consent/domain/entities/consent_record.dart';
import 'package:mocktail/mocktail.dart';

class MockLocal extends Mock implements ConsentLocalDataSource {}

void main() {
  late MockLocal local;
  late ConsentRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const ConsentRecordModel(agreed: false));
  });

  setUp(() {
    local = MockLocal();
    repository = ConsentRepositoryImpl(local);
  });

  group('read', () {
    test('returns the stored record', () async {
      final at = DateTime(2026, 9, 29);
      when(() => local.read()).thenAnswer(
        (_) async => ConsentRecordModel(agreed: true, agreedAt: at),
      );

      final result = await repository.read();

      expect(result.getRight().toNullable()?.agreed, isTrue);
      expect(result.getRight().toNullable()?.agreedAt, at);
    });

    test('an absent record is a first start, not a failure', () async {
      when(() => local.read()).thenAnswer((_) async => null);

      final result = await repository.read();

      expect(result.getRight().toNullable(), ConsentRecord.none);
    });

    test('an exception becomes a CacheFailure', () async {
      when(() => local.read()).thenThrow(Exception('disk'));

      final result = await repository.read();

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });

  group('write', () {
    test('stores the record', () async {
      when(() => local.write(any())).thenAnswer((_) async {});

      final result = await repository.write(
        ConsentRecord(agreed: true, agreedAt: DateTime(2026, 9, 29)),
      );

      expect(result.isRight(), isTrue);
      final written = verify(() => local.write(captureAny())).captured.single
          as ConsentRecordModel;
      expect(written.agreed, isTrue);
    });

    test('an exception becomes a CacheFailure', () async {
      when(() => local.write(any())).thenThrow(Exception('full'));

      final result = await repository.write(ConsentRecord.none);

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });

  group('ConsentRecordModel', () {
    test('survives a round trip through JSON', () {
      final model = ConsentRecordModel(
        agreed: true,
        agreedAt: DateTime.utc(2026, 9, 29, 12),
      );

      final parsed = ConsentRecordModel.fromJson(model.toJson());

      expect(parsed.agreed, isTrue);
      expect(parsed.agreedAt, DateTime.utc(2026, 9, 29, 12));
    });

    test('omits the date when the user did not agree', () {
      expect(
        const ConsentRecordModel(agreed: false).toJson().containsKey('agreed_at'),
        isFalse,
      );
    });

    test('reads a record that has no date', () {
      final parsed = ConsentRecordModel.fromJson({'agreed': false});

      expect(parsed.agreed, isFalse);
      expect(parsed.agreedAt, isNull);
    });
  });
}
