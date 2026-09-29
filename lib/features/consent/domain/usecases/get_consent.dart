import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/consent_record.dart';
import '../repositories/consent_repository.dart';

/// Reads the stored agreement at the start of the app.
class GetConsent extends UseCase<ConsentRecord, NoParams> {
  GetConsent(this._repository);

  final ConsentRepository _repository;

  @override
  Future<Either<Failure, ConsentRecord>> call(NoParams params) =>
      _repository.read();
}
