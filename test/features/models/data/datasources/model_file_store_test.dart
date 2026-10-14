import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/features/models/data/datasources/model_file_store.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/crop.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/model_manifest.dart';

import '../../../../support/model_fixtures.dart';

void main() {
  late Directory root;
  late ModelFileStoreImpl store;

  const crop = Crop(
    code: 'coffee',
    displayName: 'Cà phê',
    datasets: [
      CropDataset(
        name: 'rocole',
        displayName: 'Lá cà phê (RoCoLe)',
        version: 3,
      ),
    ],
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('model_store_');
    store = ModelFileStoreImpl(directory: () async => root);
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<void> saveVersion(int version) => store.save(
    crop: crop,
    dataset: crop.datasets.single,
    manifest: platformManifest(version: version),
    bytes: Uint8List.fromList([version]),
  );

  test('a saved model reads back as a released model on disk', () async {
    final saved = await store.save(
      crop: crop,
      dataset: crop.datasets.single,
      manifest: platformManifest(version: 3),
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(saved.id, 'rocole');
    expect(saved.datasetName, 'rocole');
    expect(saved.displayName, 'Lá cà phê (RoCoLe)');
    expect(saved.dataset, 'Cà phê');
    expect(saved.version, '3');
    expect(saved.modelAsset, isNull);
    expect(File(saved.modelFile!).readAsBytesSync(), [1, 2, 3]);

    final read = await store.readLatest('rocole');
    expect(read, saved);
    expect(read!.manifest.modelVersionRef, 'leaf-disease-rocole/3');
    expect(read.labelNames, ['Healthy', 'Rust']);
  });

  test('readLatest returns null for a dataset with no file', () async {
    expect(await store.readLatest('rocole'), isNull);
  });

  test('readLatest returns the highest version', () async {
    await saveVersion(2);
    await saveVersion(10);

    expect((await store.readLatest('rocole'))!.version, '10');
  });

  test('a save keeps the previous version and removes older ones', () async {
    await saveVersion(1);
    await saveVersion(2);
    await saveVersion(3);

    final versions =
        Directory('${root.path}/models/rocole')
            .listSync()
            .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
            .toList()
          ..sort();
    expect(versions, ['2', '3']);
  });

  test('a folder without a manifest is not a model', () async {
    await saveVersion(2);
    Directory('${root.path}/models/rocole/5').createSync(recursive: true);
    File('${root.path}/models/rocole/5/model.onnx').writeAsBytesSync([5]);

    expect((await store.readLatest('rocole'))!.version, '2');
  });

  test('readAll returns the latest model of each dataset', () async {
    await saveVersion(1);
    await saveVersion(2);
    await store.save(
      crop: const Crop(
        code: 'durian',
        displayName: 'Sầu riêng',
        datasets: [
          CropDataset(name: 'durian', displayName: 'Lá sầu riêng', version: 1),
        ],
      ),
      dataset: const CropDataset(
        name: 'durian',
        displayName: 'Lá sầu riêng',
        version: 1,
      ),
      manifest: platformManifest(version: 1, model: 'leaf-disease-durian'),
      bytes: Uint8List.fromList([9]),
    );

    final all = await store.readAll();

    expect(all.map((m) => '${m.id}@${m.version}').toList()..sort(), [
      'durian@1',
      'rocole@2',
    ]);
  });

  test('the manifest type stays the platform one', () async {
    await saveVersion(4);
    final read = await store.readLatest('rocole');

    expect(read!.manifest, isA<ModelManifest>());
    expect(read.manifest.released, isTrue);
  });
}
