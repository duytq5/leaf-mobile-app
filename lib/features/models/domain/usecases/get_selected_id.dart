import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/model_catalog_repository.dart';

/// Reads the id of the model the user selected last.
class GetSelectedId extends UseCase<String?, NoParams> {
  GetSelectedId(this.repository);

  final ModelCatalogRepository repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) async {
    try {
      return Right(repository.selectedId());
    } catch (error) {
      return Left(CacheFailure('the app cannot read the selection: $error'));
    }
  }
}
