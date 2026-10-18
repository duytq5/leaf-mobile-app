import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/model_catalog_repository.dart';

/// Removes a downloaded model from this phone.
class DeleteModel extends UseCase<Unit, String> {
  DeleteModel(this.repository);

  final ModelCatalogRepository repository;

  @override
  Future<Either<Failure, Unit>> call(String params) => repository.delete(params);
}
