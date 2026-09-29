import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/consent_record.dart';
import '../repositories/consent_repository.dart';

/// Stores the agreement of the user.
class SaveConsent extends UseCase<Unit, ConsentRecord> {
  SaveConsent(this._repository);

  final ConsentRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ConsentRecord params) =>
      _repository.write(params);
}
