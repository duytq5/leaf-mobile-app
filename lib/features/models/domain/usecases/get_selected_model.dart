import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/leaf_model.dart';
import '../repositories/model_catalog_repository.dart';

/// Reads the model the user selected last.
class GetSelectedModel extends UseCase<LeafModel, NoParams> {
  GetSelectedModel(this.repository);

  final ModelCatalogRepository repository;

  @override
  Future<Either<Failure, LeafModel>> call(NoParams params) =>
      repository.getSelected();
}
