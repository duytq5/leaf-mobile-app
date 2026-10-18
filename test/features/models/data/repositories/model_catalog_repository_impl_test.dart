import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:leaf_disease_mobile/core/error/api_exception.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/features/models/data/datasources/model_catalog_local_data_source.dart';
import 'package:leaf_disease_mobile/features/models/data/datasources/model_file_store.dart';
import 'package:leaf_disease_mobile/features/models/data/datasources/model_remote_data_source.dart';
import 'package:leaf_disease_mobile/features/models/data/repositories/model_catalog_repository_impl.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/catalog_entry.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/crop.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/device_config.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/leaf_model.dart';
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

CatalogEntry _entry({LeafModel? installed, int? released = 3}) => CatalogEntry(
  id: 'rocole',
  displayName: 'Lá cà phê (RoCoLe)',
  cropName: 'Cà phê',
  releasedVersion: released,
  installed: installed,
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
    when(() => remote.getCrops()).thenAnswer((_) async => [_crop]);
    when(() => files.readLatest('rocole')).thenAnswer((_) async => null);
    when(() => files.readAll()).thenAnswer((_) async => []);
    when(() => remote.getDeviceConfig('rocole'))
        .thenAnswer((_) async => _config());
    when(() => remote.getManifest(any()))
        .thenAnswer((_) async => platformManifest(version: 3));
    when(
      () => remote.download(any(), onProgress: any(named: 'onProgress')),
    ).thenAnswer((_) async => _bytes);
    when(
      () => files.save(
        crop: any(named: 'crop'),
        dataset: any(named: 'dataset'),
        manifest: any(named: 'manifest'),
        bytes: any(named: 'bytes'),
      ),
    ).thenAnswer((_) async => _downloaded(3));
  });

  group('getCatalog', () {
    test('lists a released model that is not on the phone', () async {
      final result = await repository.getCatalog();

      final entry = result.getRight().toNullable()!.single;
      expect(entry, _entry());
      expect(entry.status, ModelStatus.notDownloaded);
    });

    test('downloads nothing while it builds the list', () async {
      await repository.getCatalog();

      verifyNever(() => remote.getDeviceConfig(any()));
      verifyNever(
        () => remote.download(any(), onProgress: any(named: 'onProgress')),
      );
    });

    test('a model of the current version is downloaded', () async {
      when(() => files.readLatest('rocole'))
          .thenAnswer((_) async => _downloaded(3));

      final entry = (await repository.getCatalog()).getRight().toNullable()!;

      expect(entry.single.status, ModelStatus.downloaded);
    });

    test('an older model on the phone has an update', () async {
      when(() => files.readLatest('rocole'))
          .thenAnswer((_) async => _downloaded(2));

      final entry = (await repository.getCatalog()).getRight().toNullable()!;

      expect(entry.single.status, ModelStatus.updateAvailable);
      expect(entry.single.installed, _downloaded(2));
    });

    test('a model on disk that is no longer released stays listed', () async {
      when(() => remote.getCrops()).thenAnswer((_) async => []);
      when(() => files.readAll()).thenAnswer((_) async => [_downloaded(2)]);

      final entries = (await repository.getCatalog()).getRight().toNullable()!;

      expect(entries, [_entry(installed: _downloaded(2), released: null)]);
      expect(entries.single.status, ModelStatus.downloaded);
    });

    test('lists nothing before the platform releases a model', () async {
      when(() => remote.getCrops()).thenAnswer((_) async => []);

      final result = await repository.getCatalog();

      expect(result.getRight().toNullable(), isEmpty);
    });

    test('offline it lists the models on disk', () async {
      when(() => remote.getCrops())
          .thenThrow(const ApiException.offline('no network'));
      when(() => files.readAll()).thenAnswer((_) async => [_downloaded(2)]);

      final entries = (await repository.getCatalog()).getRight().toNullable()!;

      expect(entries, [_entry(installed: _downloaded(2), released: null)]);
    });

    test('offline with nothing on disk says the phone is offline', () async {
      when(() => remote.getCrops())
          .thenThrow(const ApiException.offline('no network'));

      final result = await repository.getCatalog();

      expect(
        result.getLeft().toNullable(),
        isA<NetworkFailure>().having((f) => f.code, 'code', FailureCode.catalogOffline),
      );
    });

    test('an unexpected error becomes a ModelFailure', () async {
      when(() => remote.getCrops()).thenThrow(Exception('bad body'));

      final result = await repository.getCatalog();

      expect(
        result.getLeft().toNullable(),
        isA<ModelFailure>().having((f) => f.code, 'code', FailureCode.catalogUnreadable),
      );
    });
  });

  group('download', () {
    setUp(() => repository.getCatalog());

    test('downloads, checks and stores the current release', () async {
      final result = await repository.download('rocole');

      expect(result.getRight().toNullable(), _downloaded(3));
      verify(
        () => files.save(
          crop: _crop,
          dataset: _dataset,
          manifest: any(named: 'manifest'),
          bytes: _bytes,
        ),
      ).called(1);
    });

    test('passes the progress on', () async {
      when(
        () => remote.download(any(), onProgress: any(named: 'onProgress')),
      ).thenAnswer((invocation) async {
        final report =
            invocation.namedArguments[#onProgress] as void Function(double?);
        report(0.5);
        report(1);
        return _bytes;
      });
      final seen = <double?>[];

      await repository.download('rocole', onProgress: seen.add);

      expect(seen, [0.5, 1]);
    });

    test('a file with the wrong hash is not stored', () async {
      when(() => remote.getDeviceConfig('rocole'))
          .thenAnswer((_) async => _config(sha: 'cd' * 32));

      final result = await repository.download('rocole');

      expect(
        result.getLeft().toNullable(),
        isA<ModelFailure>().having((f) => f.code, 'code', FailureCode.downloadDamaged),
      );
      verifyNever(
        () => files.save(
          crop: any(named: 'crop'),
          dataset: any(named: 'dataset'),
          manifest: any(named: 'manifest'),
          bytes: any(named: 'bytes'),
        ),
      );
    });

    test('a failed request says why', () async {
      when(
        () => remote.download(any(), onProgress: any(named: 'onProgress')),
      ).thenThrow(const ApiException(status: 403, message: 'expired'));

      final result = await repository.download('rocole');

      expect(
        result.getLeft().toNullable(),
        isA<NetworkFailure>().having((f) => f.code, 'code', FailureCode.downloadFailed),
      );
    });

    test('a dataset with no release cannot be downloaded', () async {
      when(() => remote.getDeviceConfig('rocole')).thenAnswer((_) async => null);

      final result = await repository.download('rocole');

      expect(
        result.getLeft().toNullable(),
        isA<ModelFailure>().having((f) => f.code, 'code', FailureCode.modelNotReleased),
      );
    });

    test('a dataset the list does not hold cannot be downloaded', () async {
      final result = await repository.download('durian');

      expect(
        result.getLeft().toNullable(),
        isA<ModelFailure>().having((f) => f.code, 'code', FailureCode.modelNotReleased),
      );
    });
  });

  group('delete', () {
    test('removes the model from the phone', () async {
      when(() => files.delete('rocole')).thenAnswer((_) async {});

      final result = await repository.delete('rocole');

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => files.delete('rocole')).called(1);
    });

    test('an exception becomes a CacheFailure', () async {
      when(() => files.delete('rocole')).thenThrow(Exception('busy'));

      final result = await repository.delete('rocole');

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });

  group('select', () {
    test('stores the id', () async {
      when(() => local.writeSelectedId(any())).thenAnswer((_) async {});

      final result = await repository.select('durian');

      expect(result.isRight(), isTrue);
      verify(() => local.writeSelectedId('durian')).called(1);
    });

    test('reads the stored id', () {
      when(() => local.readSelectedId()).thenReturn('rocole');

      expect(repository.selectedId(), 'rocole');
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
  });
}
