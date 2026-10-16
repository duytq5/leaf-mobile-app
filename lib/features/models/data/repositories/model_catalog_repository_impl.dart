import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/leaf_model.dart';
import '../../domain/repositories/model_catalog_repository.dart';
import '../datasources/model_catalog_local_data_source.dart';
import '../datasources/model_file_store.dart';
import '../datasources/model_remote_data_source.dart';

/// Lists the current model of each released dataset (design doc F5).
///
/// The platform's crops come first. A dataset whose cached model is the
/// current release needs no download. A new release is downloaded, its SHA-256
/// is checked, and it replaces the cached one, which stays as the fallback.
/// Offline, the app lists the models on disk. The app ships no model, so with
/// no release the list is empty, and offline with nothing on disk it fails.
class ModelCatalogRepositoryImpl implements ModelCatalogRepository {
  ModelCatalogRepositoryImpl(
    this._local, {
    required this.remote,
    required this.files,
  });

  final ModelCatalogLocalDataSource _local;
  final ModelRemoteDataSource remote;
  final ModelFileStore files;

  /// The list of the last [getModels], so [getSelected] does not read the
  /// network again.
  List<LeafModel>? _models;

  @override
  Future<Either<Failure, List<LeafModel>>> getModels() async {
    try {
      final models = await _currentModels();
      _models = models;
      return Right(models);
    } on _Offline {
      return const Left(
        NetworkFailure(
          'No connection. Connect to the internet to download a model.',
        ),
      );
    } catch (error) {
      return Left(ModelFailure('the app cannot read the models: $error'));
    }
  }

  @override
  Future<Either<Failure, LeafModel>> getSelected() async {
    try {
      final models = _models ?? await _currentModels();
      final id = _local.readSelectedId();

      // A stored id that names no model falls back to the first model. This
      // happens when a release removes a model the user had selected.
      return Right(
        models.firstWhere(
          (model) => model.id == id,
          orElse: () => models.first,
        ),
      );
    } catch (error) {
      return Left(ModelFailure('the app cannot read the models: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> select(String id) async {
    try {
      await _local.writeSelectedId(id);
      return const Right(unit);
    } catch (error) {
      return Left(CacheFailure('the app cannot store the selection: $error'));
    }
  }

  Future<List<LeafModel>> _currentModels() async {
    List<Crop> crops;
    try {
      crops = await remote.getCrops();
    } on ApiException {
      // Offline, or the platform is stopped. The models on disk still run.
      final cached = await files.readAll();
      if (cached.isEmpty) throw const _Offline();
      return cached;
    }

    final models = <LeafModel>[];
    for (final crop in crops) {
      for (final dataset in crop.datasets) {
        final model = await _currentModel(crop, dataset);
        if (model != null) models.add(model);
      }
    }
    return models;
  }

  /// The current model of [dataset], or the cached one when the download
  /// fails, or null when there is neither.
  Future<LeafModel?> _currentModel(Crop crop, CropDataset dataset) async {
    final cached = await files.readLatest(dataset.name);
    if (cached != null && cached.version == '${dataset.version}') {
      return cached;
    }

    try {
      final config = await remote.getDeviceConfig(dataset.name);
      if (config == null) return cached;

      final manifest = await remote.getManifest(config.manifestUrl);
      final bytes = await remote.download(config.modelUrl);
      if (sha256.convert(bytes).toString() != config.sha256) {
        // A damaged or replaced file never runs.
        return cached;
      }
      return await files.save(
        crop: crop,
        dataset: dataset,
        manifest: manifest,
        bytes: bytes,
      );
    } catch (_) {
      return cached;
    }
  }
}

/// The platform cannot be reached and no model is on disk.
class _Offline implements Exception {
  const _Offline();
}
