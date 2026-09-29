import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/consent_record.dart';
import '../../domain/repositories/consent_repository.dart';
import '../datasources/consent_local_data_source.dart';
import '../models/consent_record_model.dart';

class ConsentRepositoryImpl implements ConsentRepository {
  ConsentRepositoryImpl(this._local);

  final ConsentLocalDataSource _local;

  @override
  Future<Either<Failure, ConsentRecord>> read() async {
    try {
      final stored = await _local.read();
      // An absent record is a normal first start, not a failure.
      return Right(stored ?? ConsentRecord.none);
    } catch (error) {
      return Left(CacheFailure('the device store does not answer: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> write(ConsentRecord record) async {
    try {
      await _local.write(ConsentRecordModel.fromEntity(record));
      return const Right(unit);
    } catch (error) {
      return Left(CacheFailure('the app cannot store the answer: $error'));
    }
  }
}
