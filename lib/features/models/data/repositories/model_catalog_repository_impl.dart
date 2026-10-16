import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/catalog_entry.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/leaf_model.dart';
import '../../domain/repositories/model_catalog_repository.dart';
import '../datasources/model_catalog_local_data_source.dart';
import '../datasources/model_file_store.dart';
import '../datasources/model_remote_data_source.dart';

/// Lists the platform's models and lets the user download them (design doc
/// F5).
///
/// The list comes from `GET /v1/crops` and the models on disk, and downloads
/// nothing, so a long list opens at once. A download fetches the current
/// release, checks its SHA-256 and stores it next to the previous version.
/// Offline, the app lists the models on disk. The app ships no model, so
/// offline with nothing on disk the list fails.
class ModelCatalogRepositoryImpl implements ModelCatalogRepository {
  ModelCatalogRepositoryImpl(
    this._local, {
    required this.remote,
    required this.files,
  });

  final ModelCatalogLocalDataSource _local;
  final ModelRemoteDataSource remote;
  final ModelFileStore files;

  /// The crop and dataset of each released id of the last [getCatalog], which
  /// a download needs to store the model's card.
  final Map<String, (Crop, CropDataset)> _released = {};

  @override
  Future<Either<Failure, List<CatalogEntry>>> getCatalog() async {
    try {
      final List<Crop> crops;
      try {
        crops = await remote.getCrops();
      } on ApiException {
        // Offline, or the platform is stopped. The models on disk still run.
        final onDisk = await files.readAll();
        if (onDisk.isEmpty) {
          return const Left(
            NetworkFailure(
              'No connection. Connect to the internet to download a model.',
            ),
          );
        }
        return Right([for (final model in onDisk) _entryOf(model)]);
      }

      _released.clear();
      final entries = <CatalogEntry>[];
      for (final crop in crops) {
        for (final dataset in crop.datasets) {
          _released[dataset.name] = (crop, dataset);
          entries.add(
            CatalogEntry(
              id: dataset.name,
              displayName: dataset.displayName,
              cropName: crop.displayName,
              releasedVersion: dataset.version,
              installed: await files.readLatest(dataset.name),
            ),
          );
        }
      }
      // A model the platform no longer lists stays, so the user can delete it.
      for (final model in await files.readAll()) {
        if (!_released.containsKey(model.id)) entries.add(_entryOf(model));
      }
      return Right(entries);
    } catch (error) {
      return Left(ModelFailure('the app cannot read the models: $error'));
    }
  }

  @override
  Future<Either<Failure, LeafModel>> download(
    String id, {
    void Function(double? progress)? onProgress,
  }) async {
    final released = _released[id];
    if (released == null) {
      return const Left(ModelFailure('This model is not released.'));
    }
    final (crop, dataset) = released;

    try {
      final config = await remote.getDeviceConfig(id);
      if (config == null) {
        return const Left(ModelFailure('This model is not released.'));
      }
      final manifest = await remote.getManifest(config.manifestUrl);
      final bytes = await remote.download(
        config.modelUrl,
        onProgress: onProgress,
      );
      if (sha256.convert(bytes).toString() != config.sha256) {
        // A damaged or replaced file never runs.
        return const Left(
          ModelFailure('The download was damaged. Please try again.'),
        );
      }
      return Right(
        await files.save(
          crop: crop,
          dataset: dataset,
          manifest: manifest,
          bytes: bytes,
        ),
      );
    } on ApiException catch (error) {
      return Left(
        NetworkFailure(
          error.offline
              ? 'No connection. The download did not finish.'
              : 'The download failed: ${error.message}',
        ),
      );
    } catch (error) {
      return Left(ModelFailure('The download failed: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    try {
      await files.delete(id);
      return const Right(unit);
    } catch (error) {
      return Left(CacheFailure('the app cannot delete the model: $error'));
    }
  }

  @override
  String? selectedId() => _local.readSelectedId();

  @override
  Future<Either<Failure, Unit>> select(String id) async {
    try {
      await _local.writeSelectedId(id);
      return const Right(unit);
    } catch (error) {
      return Left(CacheFailure('the app cannot store the selection: $error'));
    }
  }

  CatalogEntry _entryOf(LeafModel model) => CatalogEntry(
    id: model.id,
    displayName: model.displayName,
    cropName: model.dataset,
    installed: model,
  );
}
