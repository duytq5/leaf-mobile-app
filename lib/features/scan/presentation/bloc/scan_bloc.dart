import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../models/domain/entities/leaf_model.dart';
import '../../domain/entities/image_source_kind.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/usecases/classify_image.dart';
import '../../domain/usecases/pick_image.dart';

sealed class ScanEvent extends Equatable {
  const ScanEvent();

  @override
  List<Object?> get props => [];
}

/// The user taps "Take photo" or "Choose from library".
class ScanImageRequested extends ScanEvent {
  const ScanImageRequested({required this.source, required this.model});

  final ImageSourceKind source;
  final LeafModel model;

  @override
  List<Object?> get props => [source, model];
}

/// The user leaves the result screen.
class ScanCleared extends ScanEvent {
  const ScanCleared();
}

enum ScanStatus { idle, picking, running, done, failure }

class ScanState extends Equatable {
  const ScanState({this.status = ScanStatus.idle, this.result, this.failure});

  final ScanStatus status;
  final ScanResult? result;
  final Failure? failure;

  bool get busy => status == ScanStatus.picking || status == ScanStatus.running;

  @override
  List<Object?> get props => [status, result, failure];
}

/// Holds the state of one scan.
class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc({required this.pickImage, required this.classifyImage})
    : super(const ScanState()) {
    on<ScanImageRequested>(_onRequested);
    on<ScanCleared>((_, emit) => emit(const ScanState()));
  }

  final PickImage pickImage;
  final ClassifyImage classifyImage;

  Future<void> _onRequested(
    ScanImageRequested event,
    Emitter<ScanState> emit,
  ) async {
    emit(const ScanState(status: ScanStatus.picking));

    final picked = await pickImage(event.source);
    if (picked.isLeft()) {
      // A cancelled picker is not an error. The screen returns to rest with no
      // message.
      emit(const ScanState());
      return;
    }

    emit(const ScanState(status: ScanStatus.running));

    final classified = await classifyImage(
      ClassifyParams(
        bytes: picked.getRight().toNullable()!,
        model: event.model,
      ),
    );

    emit(
      classified.match(
        (failure) =>
            ScanState(status: ScanStatus.failure, failure: failure),
        (result) => ScanState(status: ScanStatus.done, result: result),
      ),
    );
  }
}
