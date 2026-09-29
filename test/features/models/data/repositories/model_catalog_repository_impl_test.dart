import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/features/models/data/datasources/model_catalog_local_data_source.dart';
import 'package:leaf_disease_mobile/features/models/data/repositories/model_catalog_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/model_fixtures.dart';

class MockLocal extends Mock implements ModelCatalogLocalDataSource {}

void main() {
  late MockLocal local;
  late ModelCatalogRepositoryImpl repository;

  setUp(() {
    local = MockLocal();
    repository = ModelCatalogRepositoryImpl(local);
    when(() => local.readCatalog())
        .thenAnswer((_) async => [coffeeModel, durianModel]);
  });

  group('getModels', () {
    test('returns every model of the catalog', () async {
      final result = await repository.getModels();

      expect(result.getRight().toNullable(), [coffeeModel, durianModel]);
    });

    test('an exception becomes a ModelFailure', () async {
      when(() => local.readCatalog()).thenThrow(Exception('no asset'));

      final result = await repository.getModels();

      expect(result.getLeft().toNullable(), isA<ModelFailure>());
    });
  });

  group('getSelected', () {
    test('returns the stored model', () async {
      when(() => local.readSelectedId()).thenReturn('durian');

      final result = await repository.getSelected();

      expect(result.getRight().toNullable(), durianModel);
    });

    test('with no stored id it returns the first model', () async {
      when(() => local.readSelectedId()).thenReturn(null);

      final result = await repository.getSelected();

      expect(result.getRight().toNullable(), coffeeModel);
    });

    test('an id that names no model falls back to the first', () async {
      when(() => local.readSelectedId()).thenReturn('a_removed_model');

      final result = await repository.getSelected();

      expect(result.getRight().toNullable(), coffeeModel);
    });
  });

  group('select', () {
    test('stores the id', () async {
      when(() => local.writeSelectedId(any())).thenAnswer((_) async {});

      final result = await repository.select('durian');

      expect(result.isRight(), isTrue);
      verify(() => local.writeSelectedId('durian')).called(1);
    });

    test('an exception becomes a CacheFailure', () async {
      when(() => local.writeSelectedId(any())).thenThrow(Exception('full'));

      final result = await repository.select('durian');

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });

  group('LeafModel', () {
    test('reads the labels from its manifest', () {
      expect(coffeeModel.labelCount, 3);
      expect(durianModel.labelCount, 6);
    });

    test('builds the subtitle of the card from the manifest', () {
      expect(coffeeModel.subtitle, 'RoCoLe · fold-1-best · 3 labels');
      expect(durianModel.subtitle, 'Vietnamese durian · fold-3-best · 6 labels');
    });
  });
}
