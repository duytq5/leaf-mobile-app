import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/leaf_model.dart';
import '../repositories/model_catalog_repository.dart';

/// Reads every model of the catalog for the picker.
class GetModels extends UseCase<List<LeafModel>, NoParams> {
  GetModels(this.repository);

  final ModelCatalogRepository repository;

  @override
  Future<Either<Failure, List<LeafModel>>> call(NoParams params) =>
      repository.getModels();
}
