import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../models/domain/entities/leaf_model.dart';
import '../../../scan/domain/entities/scan_result.dart';

/// What one [OutboxRepository.send] did.
class OutboxReport extends Equatable {
  const OutboxReport({this.sent = 0, this.dropped = 0, this.left = 0});

  /// Captures the platform accepted.
  final int sent;

  /// Captures the platform refused for good, for example a model version it
  /// no longer knows.
  final int dropped;

  /// Captures still waiting, for example because the phone went offline.
  final int left;

  @override
  List<Object?> get props => [sent, dropped, left];
}

/// Stores every scan of a released model and sends it when the phone is
/// online and the user is signed in.
abstract class OutboxRepository {
  Future<Either<Failure, Unit>> enqueue(ScanResult result, LeafModel model);

  /// Sends the waiting captures, oldest first, until one cannot go.
  Future<Either<Failure, OutboxReport>> send();

  Future<int> pendingCount();

  /// Fires when the phone gets a network again.
  Stream<void> get onlineAgain;
}
