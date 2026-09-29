import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/consent_record.dart';

/// Reads and writes the agreement of the user.
abstract class ConsentRepository {
  /// Returns [ConsentRecord.none] when the user did not answer yet.
  Future<Either<Failure, ConsentRecord>> read();

  Future<Either<Failure, Unit>> write(ConsentRecord record);
}
