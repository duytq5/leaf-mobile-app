import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/leaf_model.dart';
import '../repositories/model_catalog_repository.dart';

class DownloadModelParams extends Equatable {
  const DownloadModelParams(this.id, {this.onProgress});

  final String id;

  /// A fraction from 0 to 1, or null when the size is unknown.
  final void Function(double? progress)? onProgress;

  @override
  List<Object?> get props => [id];
}

/// Downloads the current release of one model, on the user's request.
class DownloadModel extends UseCase<LeafModel, DownloadModelParams> {
  DownloadModel(this.repository);

  final ModelCatalogRepository repository;

  @override
  Future<Either<Failure, LeafModel>> call(DownloadModelParams params) =>
      repository.download(params.id, onProgress: params.onProgress);
}
