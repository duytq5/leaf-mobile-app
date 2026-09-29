import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/domain/entities/leaf_model.dart';
import '../../domain/entities/label_correction.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/usecases/submit_correction.dart';

sealed class CorrectionEvent extends Equatable {
  const CorrectionEvent();

  @override
  List<Object?> get props => [];
}

/// The user taps a radio row.
class CorrectionLabelChosen extends CorrectionEvent {
  const CorrectionLabelChosen(this.label);

  final String label;

  @override
  List<Object?> get props => [label];
}

/// The user taps "Submit correction".
class CorrectionSubmitted extends CorrectionEvent {
  const CorrectionSubmitted();
}

enum CorrectionStatus { editing, saving, saved, failure }

class CorrectionState extends Equatable {
  const CorrectionState({
    this.status = CorrectionStatus.editing,
    this.chosen,
    this.message,
  });

  final CorrectionStatus status;

  /// The label the user selected. The button stays disabled while it is null.
  final String? chosen;

  final String? message;

  CorrectionState copyWith({
    CorrectionStatus? status,
    String? chosen,
    String? message,
  }) {
    return CorrectionState(
      status: status ?? this.status,
      chosen: chosen ?? this.chosen,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, chosen, message];
}

/// Holds the state of the correction screen.
class CorrectionBloc extends Bloc<CorrectionEvent, CorrectionState> {
  CorrectionBloc({
    required this.submitCorrection,
    required this.result,
    required this.model,
  }) : super(const CorrectionState()) {
    on<CorrectionLabelChosen>(
      (event, emit) => emit(state.copyWith(chosen: event.label)),
    );
    on<CorrectionSubmitted>(_onSubmitted);
  }

  final SubmitCorrection submitCorrection;
  final ScanResult result;
  final LeafModel model;

  /// The rows of the screen: every label of the model, then one escape row.
  List<String> get choices => [...model.labels, LabelCorrection.notSure];

  Future<void> _onSubmitted(
    CorrectionSubmitted event,
    Emitter<CorrectionState> emit,
  ) async {
    final chosen = state.chosen;
    if (chosen == null) return;

    emit(state.copyWith(status: CorrectionStatus.saving));

    final correction = LabelCorrection(
      modelId: result.modelId,
      modelVersion: result.modelVersion,
      predictedLabel: result.top.label,
      correctedLabel: chosen,
      submittedAt: DateTime.now(),
    );
    final outcome = await submitCorrection(correction);

    emit(
      outcome.match(
        (failure) => state.copyWith(
          status: CorrectionStatus.failure,
          message: failure.message,
        ),
        (_) => state.copyWith(status: CorrectionStatus.saved),
      ),
    );
  }
}
