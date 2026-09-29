import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/leaf_model.dart';
import '../../domain/repositories/model_catalog_repository.dart';
import '../datasources/model_catalog_local_data_source.dart';

class ModelCatalogRepositoryImpl implements ModelCatalogRepository {
  ModelCatalogRepositoryImpl(this._local);

  final ModelCatalogLocalDataSource _local;

  @override
  Future<Either<Failure, List<LeafModel>>> getModels() async {
    try {
      return Right(await _local.readCatalog());
    } catch (error) {
      return Left(ModelFailure('the app cannot read the models: $error'));
    }
  }

  @override
  Future<Either<Failure, LeafModel>> getSelected() async {
    try {
      final models = await _local.readCatalog();
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
}
