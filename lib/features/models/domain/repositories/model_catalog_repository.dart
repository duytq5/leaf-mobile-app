import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/catalog_entry.dart';
import '../entities/leaf_model.dart';

/// Lists the platform's models, downloads and deletes them on request, and
/// holds the selection.
abstract class ModelCatalogRepository {
  /// Every released model, with the version on this phone if any. It
  /// downloads nothing.
  Future<Either<Failure, List<CatalogEntry>>> getCatalog();

  /// Downloads the current release of [id], checks its SHA-256 and stores it.
  /// [onProgress] gets a fraction from 0 to 1, or null when the size is
  /// unknown.
  Future<Either<Failure, LeafModel>> download(
    String id, {
    void Function(double? progress)? onProgress,
  });

  /// Removes every version of [id] from this phone.
  Future<Either<Failure, Unit>> delete(String id);

  /// The id the user selected last, or null.
  String? selectedId();

  Future<Either<Failure, Unit>> select(String id);
}
