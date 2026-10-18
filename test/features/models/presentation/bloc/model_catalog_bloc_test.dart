import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/core/usecase/usecase.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/catalog_entry.dart';
import 'package:leaf_disease_mobile/features/models/domain/usecases/delete_model.dart';
import 'package:leaf_disease_mobile/features/models/domain/usecases/download_model.dart';
import 'package:leaf_disease_mobile/features/models/domain/usecases/get_catalog.dart';
import 'package:leaf_disease_mobile/features/models/domain/usecases/get_selected_id.dart';
import 'package:leaf_disease_mobile/features/models/domain/usecases/select_model.dart';
import 'package:leaf_disease_mobile/features/models/presentation/bloc/model_catalog_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/model_fixtures.dart';

class MockGetCatalog extends Mock implements GetCatalog {}

class MockGetSelectedId extends Mock implements GetSelectedId {}

class MockSelectModel extends Mock implements SelectModel {}

class MockDownloadModel extends Mock implements DownloadModel {}

class MockDeleteModel extends Mock implements DeleteModel {}

final _coffee = CatalogEntry(
  id: 'coffee_rocole',
  displayName: 'Coffee Leaf',
  cropName: 'RoCoLe',
  releasedVersion: 1,
  installed: coffeeModel,
);

const _durianMissing = CatalogEntry(
  id: 'durian',
  displayName: 'Durian Leaf',
  cropName: 'Vietnamese durian',
  releasedVersion: 1,
);

final _durian = CatalogEntry(
  id: 'durian',
  displayName: 'Durian Leaf',
  cropName: 'Vietnamese durian',
  releasedVersion: 1,
  installed: durianModel,
);

void main() {
  late MockGetCatalog getCatalog;
  late MockGetSelectedId getSelectedId;
  late MockSelectModel selectModel;
  late MockDownloadModel downloadModel;
  late MockDeleteModel deleteModel;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const DownloadModelParams('x'));
  });

  setUp(() {
    getCatalog = MockGetCatalog();
    getSelectedId = MockGetSelectedId();
    selectModel = MockSelectModel();
    downloadModel = MockDownloadModel();
    deleteModel = MockDeleteModel();
    when(() => getSelectedId(any())).thenAnswer((_) async => const Right(null));
    when(() => selectModel(any())).thenAnswer((_) async => const Right(unit));
  });

  ModelCatalogBloc build() => ModelCatalogBloc(
    getCatalog: getCatalog,
    getSelectedId: getSelectedId,
    selectModel: selectModel,
    downloadModel: downloadModel,
    deleteModel: deleteModel,
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'reads the list and the stored selection',
    setUp: () {
      when(() => getCatalog(any()))
          .thenAnswer((_) async => Right([_coffee, _durian]));
      when(() => getSelectedId(any()))
          .thenAnswer((_) async => const Right('durian'));
    },
    build: build,
    act: (bloc) => bloc.add(const ModelsRequested()),
    expect: () => [
      const ModelCatalogState(status: ModelCatalogStatus.loading),
      ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_coffee, _durian],
        selectedId: 'durian',
      ),
    ],
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'a list failure shows the message',
    setUp: () => when(() => getCatalog(any()))
        .thenAnswer((_) async => const Left(NetworkFailure('offline'))),
    build: build,
    act: (bloc) => bloc.add(const ModelsRequested()),
    expect: () => const [
      ModelCatalogState(status: ModelCatalogStatus.loading),
      ModelCatalogState(status: ModelCatalogStatus.failure, message: 'offline'),
    ],
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'a tap on a downloaded model selects it and stores it',
    build: build,
    seed: () => ModelCatalogState(
      status: ModelCatalogStatus.ready,
      entries: [_coffee, _durian],
      selectedId: 'coffee_rocole',
    ),
    act: (bloc) => bloc.add(const ModelSelected('durian')),
    expect: () => [
      ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_coffee, _durian],
        selectedId: 'durian',
      ),
    ],
    verify: (_) => verify(() => selectModel('durian')).called(1),
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'a model that is not downloaded cannot be selected',
    build: build,
    seed: () => ModelCatalogState(
      status: ModelCatalogStatus.ready,
      entries: [_coffee, _durianMissing],
      selectedId: 'coffee_rocole',
    ),
    act: (bloc) => bloc.add(const ModelSelected('durian')),
    expect: () => <ModelCatalogState>[],
    verify: (_) => verifyNever(() => selectModel(any())),
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'a download shows its progress, then the model is ready and selected',
    setUp: () => when(() => downloadModel(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.single as DownloadModelParams;
      params.onProgress?.call(0.5);
      return Right(durianModel);
    }),
    build: build,
    seed: () => const ModelCatalogState(
      status: ModelCatalogStatus.ready,
      entries: [_durianMissing],
    ),
    act: (bloc) => bloc.add(const ModelDownloadRequested('durian')),
    expect: () => [
      const ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_durianMissing],
        progress: {'durian': null},
      ),
      const ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_durianMissing],
        progress: {'durian': 0.5},
      ),
      ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_durian],
        selectedId: 'durian',
      ),
    ],
    verify: (_) => verify(() => selectModel('durian')).called(1),
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'a failed download says why and leaves the model as it was',
    setUp: () => when(() => downloadModel(any()))
        .thenAnswer((_) async => const Left(NetworkFailure('link expired'))),
    build: build,
    seed: () => const ModelCatalogState(
      status: ModelCatalogStatus.ready,
      entries: [_durianMissing],
    ),
    act: (bloc) => bloc.add(const ModelDownloadRequested('durian')),
    expect: () => const [
      ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_durianMissing],
        progress: {'durian': null},
      ),
      ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_durianMissing],
        message: 'link expired',
      ),
    ],
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'a second tap while a model downloads is ignored',
    setUp: () => when(() => downloadModel(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      return Right(durianModel);
    }),
    build: build,
    seed: () => const ModelCatalogState(
      status: ModelCatalogStatus.ready,
      entries: [_durianMissing],
    ),
    act: (bloc) => bloc
      ..add(const ModelDownloadRequested('durian'))
      ..add(const ModelDownloadRequested('durian')),
    wait: const Duration(milliseconds: 20),
    verify: (_) => verify(() => downloadModel(any())).called(1),
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'deleting the selected model selects the next downloaded one',
    setUp: () => when(() => deleteModel('durian'))
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => ModelCatalogState(
      status: ModelCatalogStatus.ready,
      entries: [_coffee, _durian],
      selectedId: 'durian',
    ),
    act: (bloc) => bloc.add(const ModelDeleteRequested('durian')),
    expect: () => [
      ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_coffee, _durianMissing],
        selectedId: 'coffee_rocole',
      ),
    ],
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'deleting the last model leaves no selection',
    setUp: () => when(() => deleteModel('durian'))
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => ModelCatalogState(
      status: ModelCatalogStatus.ready,
      entries: [_durian],
      selectedId: 'durian',
    ),
    act: (bloc) => bloc.add(const ModelDeleteRequested('durian')),
    expect: () => const [
      ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_durianMissing],
      ),
    ],
  );

  blocTest<ModelCatalogBloc, ModelCatalogState>(
    'deleting a model the platform no longer releases removes its card',
    setUp: () => when(() => deleteModel('durian'))
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => ModelCatalogState(
      status: ModelCatalogStatus.ready,
      entries: [
        _coffee,
        CatalogEntry(
          id: 'durian',
          displayName: 'Durian Leaf',
          cropName: 'Vietnamese durian',
          installed: durianModel,
        ),
      ],
      selectedId: 'coffee_rocole',
    ),
    act: (bloc) => bloc.add(const ModelDeleteRequested('durian')),
    expect: () => [
      ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_coffee],
        selectedId: 'coffee_rocole',
      ),
    ],
  );

  group('the state', () {
    test('resolves the selected model from the id', () {
      final state = ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_coffee, _durian],
        selectedId: 'durian',
      );

      expect(state.selected, durianModel);
    });

    test('falls back to the first downloaded model', () {
      final state = ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_durianMissing, _coffee],
        selectedId: 'gone',
      );

      expect(state.selected, coffeeModel);
    });

    test('has no selection while nothing is downloaded', () {
      const state = ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [_durianMissing],
      );

      expect(state.selected, isNull);
    });
  });

  group('CatalogEntry', () {
    CatalogEntry entry({int? released, bool installed = true}) => CatalogEntry(
      id: 'rocole',
      displayName: 'Lá cà phê (RoCoLe)',
      cropName: 'Cà phê',
      releasedVersion: released,
      installed: installed ? releasedModel : null,
    );

    test('a model of the released version is downloaded', () {
      expect(entry(released: 3).status, ModelStatus.downloaded);
    });

    test('a newer release is an update', () {
      expect(entry(released: 4).status, ModelStatus.updateAvailable);
    });

    test('a model with no known release is downloaded', () {
      expect(entry().status, ModelStatus.downloaded);
    });

    test('a release that is not on the phone is not downloaded', () {
      expect(
        entry(released: 3, installed: false).status,
        ModelStatus.notDownloaded,
      );
    });
  });
}
