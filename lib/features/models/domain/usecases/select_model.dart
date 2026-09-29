import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/model_catalog_repository.dart';

/// Stores the model the user selects.
class SelectModel extends UseCase<Unit, String> {
  SelectModel(this.repository);

  final ModelCatalogRepository repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      repository.select(params);
}
