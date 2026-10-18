import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/catalog_entry.dart';
import '../repositories/model_catalog_repository.dart';

/// Lists the released models and what this phone holds of them.
class GetCatalog extends UseCase<List<CatalogEntry>, NoParams> {
  GetCatalog(this.repository);

  final ModelCatalogRepository repository;

  @override
  Future<Either<Failure, List<CatalogEntry>>> call(NoParams params) =>
      repository.getCatalog();
}
