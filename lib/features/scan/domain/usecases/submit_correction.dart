import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/label_correction.dart';
import '../repositories/scan_repository.dart';

/// Stores the label a person gives.
class SubmitCorrection extends UseCase<Unit, LabelCorrection> {
  SubmitCorrection(this.repository);

  final ScanRepository repository;

  @override
  Future<Either<Failure, Unit>> call(LabelCorrection params) =>
      repository.saveCorrection(params);
}
