import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/leaf_model.dart';

/// Reads the models that ship with the app and holds the selection.
abstract class ModelCatalogRepository {
  Future<Either<Failure, List<LeafModel>>> getModels();

  /// Returns the selected model. With no stored selection it returns the first
  /// model of the catalog.
  Future<Either<Failure, LeafModel>> getSelected();

  Future<Either<Failure, Unit>> select(String id);
}
