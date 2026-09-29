import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/core/usecase/usecase.dart';
import 'package:leaf_disease_mobile/features/models/domain/usecases/get_models.dart';
import 'package:leaf_disease_mobile/features/models/domain/usecases/get_selected_model.dart';
import 'package:leaf_disease_mobile/features/models/domain/usecases/select_model.dart';
import 'package:leaf_disease_mobile/features/models/presentation/bloc/model_catalog_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/model_fixtures.dart';

class MockGetModels extends Mock implements GetModels {}

class MockGetSelectedModel extends Mock implements GetSelectedModel {}

class MockSelectModel extends Mock implements SelectModel {}

void main() {
  late MockGetModels getModels;
  late MockGetSelectedModel getSelectedModel;
  late MockSelectModel selectModel;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    getModels = MockGetModels();
    getSelectedModel = MockGetSelectedModel();
    selectModel = MockSelectModel();
  });

  ModelCatalogBloc build() => ModelCatalogBloc(
    getModels: getModels,
    getSelectedModel: getSelectedModel,
    selectModel: selectModel,
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'reads the catalog and the stored selection',
    setUp: () {
      when(() => getModels(any()))
          .thenAnswer((_) async => Right([coffeeModel, durianModel]));
      when(() => getSelectedModel(any()))
          .thenAnswer((_) async => Right(durianModel));
    },
    build: build,
    act: (bloc) => bloc.add(const ModelsRequested()),
    expect: () => [
      const ModelCatalogState(status: ModelCatalogStatus.loading),
      ModelCatalogState(
        status: ModelCatalogStatus.ready,
        models: [coffeeModel, durianModel],
        selectedId: 'durian',
      ),
    ],
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'a catalog failure shows the message',
    setUp: () => when(() => getModels(any()))
        .thenAnswer((_) async => const Left(ModelFailure('no asset'))),
    build: build,
    act: (bloc) => bloc.add(const ModelsRequested()),
    expect: () => const [
      ModelCatalogState(status: ModelCatalogStatus.loading),
      ModelCatalogState(
        status: ModelCatalogStatus.failure,
        message: 'no asset',
      ),
    ],
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'a tap changes the selection at once and stores it',
    setUp: () =>
        when(() => selectModel(any())).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => ModelCatalogState(
      status: ModelCatalogStatus.ready,
      models: [coffeeModel, durianModel],
      selectedId: 'coffee_rocole',
    ),
    act: (bloc) => bloc.add(const ModelSelected('durian')),
    expect: () => [
      ModelCatalogState(
        status: ModelCatalogStatus.ready,
        models: [coffeeModel, durianModel],
        selectedId: 'durian',
      ),
    ],
    verify: (_) => verify(() => selectModel('durian')).called(1),
  );

  group('the state', () {
    test('resolves the selected model from the id', () {
      final state = ModelCatalogState(
        status: ModelCatalogStatus.ready,
        models: [coffeeModel, durianModel],
        selectedId: 'durian',
      );

      expect(state.selected, durianModel);
    });

    test('falls back to the first model when the id names none', () {
      final state = ModelCatalogState(
        status: ModelCatalogStatus.ready,
        models: [coffeeModel, durianModel],
        selectedId: 'gone',
      );

      expect(state.selected, coffeeModel);
    });

    test('has no selection while the list is empty', () {
      expect(const ModelCatalogState().selected, isNull);
    });
  });
}
