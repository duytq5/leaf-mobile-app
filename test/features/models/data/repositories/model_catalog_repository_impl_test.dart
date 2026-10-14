import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/error/api_exception.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/features/models/data/datasources/model_catalog_local_data_source.dart';
import 'package:leaf_disease_mobile/features/models/data/datasources/model_file_store.dart';
import 'package:leaf_disease_mobile/features/models/data/datasources/model_remote_data_source.dart';
import 'package:leaf_disease_mobile/features/models/data/repositories/model_catalog_repository_impl.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/crop.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/device_config.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/leaf_model.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/model_manifest.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/model_fixtures.dart';

class MockLocal extends Mock implements ModelCatalogLocalDataSource {}

class MockRemote extends Mock implements ModelRemoteDataSource {}

class MockFiles extends Mock implements ModelFileStore {}

const _dataset = CropDataset(
  name: 'rocole',
  displayName: 'Lá cà phê (RoCoLe)',
  version: 3,
);
const _crop = Crop(code: 'coffee', displayName: 'Cà phê', datasets: [_dataset]);

final _bytes = Uint8List.fromList([1, 2, 3]);

DeviceConfig _config({String? sha}) => DeviceConfig(
  dataset: 'rocole',
  model: 'leaf-disease-rocole',
  version: 3,
  sha256: sha ?? sha256.convert(_bytes).toString(),
  manifestUrl: Uri.parse('https://s3.test/manifest.json'),
  modelUrl: Uri.parse('https://s3.test/model.onnx'),
  expiresIn: const Duration(minutes: 15),
);

LeafModel _downloaded(int version) => LeafModel(
  id: 'rocole',
  datasetName: 'rocole',
  displayName: 'Lá cà phê (RoCoLe)',
  dataset: 'Cà phê',
  manifest: platformManifest(version: version),
  modelFile: '/models/rocole/$version/model.onnx',
);

void main() {
  late MockLocal local;
  late MockRemote remote;
  late MockFiles files;
  late ModelCatalogRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(_crop);
    registerFallbackValue(_dataset);
    registerFallbackValue(platformManifest(version: 1));
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(Uri());
  });

  setUp(() {
    local = MockLocal();
    remote = MockRemote();
    files = MockFiles();
    repository = ModelCatalogRepositoryImpl(
      local,
      remote: remote,
      files: files,
    );
    when(() => local.readCatalog())
        .thenAnswer((_) async => [coffeeModel, durianModel]);
    // Before any release the platform lists no crop.
    when(() => remote.getCrops()).thenAnswer((_) async => []);
    when(() => files.readAll()).thenAnswer((_) async => []);
  });

  group('getModels with a released model', () {
    setUp(() {
      when(() => remote.getCrops()).thenAnswer((_) async => [_crop]);
      when(() => files.readLatest('rocole')).thenAnswer((_) async => null);
      when(() => remote.getDeviceConfig('rocole'))
          .thenAnswer((_) async => _config());
      when(() => remote.getManifest(any()))
          .thenAnswer((_) async => platformManifest(version: 3));
      when(() => remote.download(any())).thenAnswer((_) async => _bytes);
      when(
        () => files.save(
          crop: any(named: 'crop'),
          dataset: any(named: 'dataset'),
          manifest: any(named: 'manifest'),
          bytes: any(named: 'bytes'),
        ),
      ).thenAnswer((_) async => _downloaded(3));
    });

    test('downloads the current model and lists it alone', () async {
      final result = await repository.getModels();

      expect(result.getRight().toNullable(), [_downloaded(3)]);
      verify(() => remote.download(Uri.parse('https://s3.test/model.onnx')))
          .called(1);
      verify(
        () => files.save(
          crop: _crop,
          dataset: _dataset,
          manifest: any(named: 'manifest'),
          bytes: _bytes,
        ),
      ).called(1);
    });

    test('a cached model of the current version needs no download', () async {
      when(() => files.readLatest('rocole'))
          .thenAnswer((_) async => _downloaded(3));

      final result = await repository.getModels();

      expect(result.getRight().toNullable(), [_downloaded(3)]);
      verifyNever(() => remote.getDeviceConfig(any()));
      verifyNever(() => remote.download(any()));
    });

    test('a file with the wrong hash is not saved; the cache stays', () async {
      when(() => files.readLatest('rocole'))
          .thenAnswer((_) async => _downloaded(2));
      when(() => remote.getDeviceConfig('rocole'))
          .thenAnswer((_) async => _config(sha: 'cd' * 32));

      final result = await repository.getModels();

      expect(result.getRight().toNullable(), [_downloaded(2)]);
      verifyNever(
        () => files.save(
          crop: any(named: 'crop'),
          dataset: any(named: 'dataset'),
          manifest: any(named: 'manifest'),
          bytes: any(named: 'bytes'),
        ),
      );
    });

    test('a failed download keeps the previous version', () async {
      when(() => files.readLatest('rocole'))
          .thenAnswer((_) async => _downloaded(2));
      when(() => remote.download(any()))
          .thenThrow(const ApiException(status: 403, message: 'expired'));

      final result = await repository.getModels();

      expect(result.getRight().toNullable(), [_downloaded(2)]);
    });

    test('a dataset with no model and no cache falls back to bundled', () async {
      when(() => remote.getDeviceConfig('rocole')).thenAnswer((_) async => null);

      final result = await repository.getModels();

      expect(result.getRight().toNullable(), [coffeeModel, durianModel]);
    });

    test('the list is read once for getModels and getSelected', () async {
      when(() => local.readSelectedId()).thenReturn('rocole');

      await repository.getModels();
      final selected = await repository.getSelected();

      expect(selected.getRight().toNullable(), _downloaded(3));
      verify(() => remote.getCrops()).called(1);
    });
  });

  group('getModels offline', () {
    setUp(() {
      when(() => remote.getCrops())
          .thenThrow(const ApiException.offline('no network'));
    });

    test('lists the models on disk', () async {
      when(() => files.readAll()).thenAnswer((_) async => [_downloaded(2)]);

      final result = await repository.getModels();

      expect(result.getRight().toNullable(), [_downloaded(2)]);
    });

    test('with nothing on disk lists the bundled models', () async {
      final result = await repository.getModels();

      expect(result.getRight().toNullable(), [coffeeModel, durianModel]);
    });
  });

  test('a platform manifest type is what the store receives', () {
    expect(platformManifest(version: 3), isA<ModelManifest>());
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
