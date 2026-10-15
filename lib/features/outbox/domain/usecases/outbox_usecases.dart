import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../models/domain/entities/leaf_model.dart';
import '../../../scan/domain/entities/scan_result.dart';
import '../repositories/outbox_repository.dart';

class QueueScanParams extends Equatable {
  const QueueScanParams({required this.result, required this.model});

  final ScanResult result;
  final LeafModel model;

  @override
  List<Object?> get props => [result, model];
}

/// Stores a scan so it goes to the platform when the phone is online.
class QueueScan extends UseCase<Unit, QueueScanParams> {
  QueueScan(this.repository);

  final OutboxRepository repository;

  @override
  Future<Either<Failure, Unit>> call(QueueScanParams params) =>
      repository.enqueue(params.result, params.model);
}

/// Sends the waiting scans.
class SendQueuedScans extends UseCase<OutboxReport, NoParams> {
  SendQueuedScans(this.repository);

  final OutboxRepository repository;

  @override
  Future<Either<Failure, OutboxReport>> call(NoParams params) =>
      repository.send();
}

/// Counts the waiting scans.
class CountQueuedScans extends UseCase<int, NoParams> {
  CountQueuedScans(this.repository);

  final OutboxRepository repository;

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    try {
      return Right(await repository.pendingCount());
    } catch (error) {
      return Left(CacheFailure('the app cannot read the outbox: $error'));
    }
  }

  /// Fires when the phone gets a network again.
  Stream<void> get onlineAgain => repository.onlineAgain;
}
