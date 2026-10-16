import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/crop.dart';
import '../../domain/entities/leaf_model.dart';
import '../../domain/entities/model_manifest.dart';

/// Keeps the models the app downloaded, so a scan works offline.
///
/// The layout is `models/{dataset}/{version}/` with `model.onnx`, `card.json`
/// and `manifest.json`. The manifest is written last, so a folder without it is
/// a download that did not finish. A save keeps the previous version as the
/// fallback and removes older ones.
abstract class ModelFileStore {
  /// Returns the highest complete version of [dataset], or null.
  Future<LeafModel?> readLatest(String dataset);

  /// Returns the highest complete version of every dataset on disk.
  Future<List<LeafModel>> readAll();

  /// Removes every version of [dataset]. A dataset not on disk is fine.
  Future<void> delete(String dataset);

  Future<LeafModel> save({
    required Crop crop,
    required CropDataset dataset,
    required ModelManifest manifest,
    required Uint8List bytes,
  });
}

class ModelFileStoreImpl implements ModelFileStore {
  ModelFileStoreImpl({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  /// The number of versions a dataset keeps: the current one and its fallback.
  static const keep = 2;

  final Future<Directory> Function() _directory;

  Future<Directory> _datasetDir(String dataset) async =>
      Directory('${(await _directory()).path}/models/$dataset');

  @override
  Future<LeafModel?> readLatest(String dataset) async {
    for (final dir in await _versionsNewestFirst(await _datasetDir(dataset))) {
      final model = _read(dir, dataset);
      if (model != null) return model;
    }
    return null;
  }

  @override
  Future<List<LeafModel>> readAll() async {
    final root = Directory('${(await _directory()).path}/models');
    if (!root.existsSync()) return [];

    final models = <LeafModel>[];
    for (final entry in root.listSync().whereType<Directory>()) {
      final model = await readLatest(_name(entry));
      if (model != null) models.add(model);
    }
    return models..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Future<void> delete(String dataset) async {
    final dir = await _datasetDir(dataset);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }

  @override
  Future<LeafModel> save({
    required Crop crop,
    required CropDataset dataset,
    required ModelManifest manifest,
    required Uint8List bytes,
  }) async {
    final datasetDir = await _datasetDir(dataset.name);
    final dir = Directory('${datasetDir.path}/${manifest.version}')
      ..createSync(recursive: true);

    File('${dir.path}/model.onnx').writeAsBytesSync(bytes, flush: true);
    File('${dir.path}/card.json').writeAsStringSync(
      jsonEncode({
        'display_name': dataset.displayName,
        'crop': crop.displayName,
      }),
      flush: true,
    );
    File('${dir.path}/manifest.json')
        .writeAsStringSync(jsonEncode(manifest.toPlatformJson()), flush: true);

    final versions = await _versionsNewestFirst(datasetDir);
    for (final old in versions.skip(keep)) {
      old.deleteSync(recursive: true);
    }
    return _read(dir, dataset.name)!;
  }

  LeafModel? _read(Directory dir, String dataset) {
    final manifestFile = File('${dir.path}/manifest.json');
    final cardFile = File('${dir.path}/card.json');
    final modelFile = File('${dir.path}/model.onnx');
    if (!manifestFile.existsSync() ||
        !cardFile.existsSync() ||
        !modelFile.existsSync()) {
      return null;
    }

    try {
      final manifest = ModelManifest.fromPlatformJson(
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>,
      );
      final card = jsonDecode(cardFile.readAsStringSync()) as Map;
      return LeafModel(
        id: dataset,
        datasetName: dataset,
        displayName: card['display_name'] as String,
        dataset: card['crop'] as String,
        manifest: manifest,
        modelFile: modelFile.path,
      );
    } on Exception {
      // A damaged folder is skipped, so the previous version takes over.
      return null;
    }
  }

  Future<List<Directory>> _versionsNewestFirst(Directory datasetDir) async {
    if (!datasetDir.existsSync()) return [];
    final versions = datasetDir
        .listSync()
        .whereType<Directory>()
        .where((dir) => int.tryParse(_name(dir)) != null)
        .toList();
    versions.sort((a, b) => int.parse(_name(b)).compareTo(int.parse(_name(a))));
    return versions;
  }

  String _name(Directory dir) =>
      dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
}
