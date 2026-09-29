import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/consent_record.dart';
import '../../domain/usecases/get_consent.dart';
import '../../domain/usecases/save_consent.dart';

sealed class ConsentEvent extends Equatable {
  const ConsentEvent();

  @override
  List<Object?> get props => [];
}

/// The app starts. Read the stored answer.
class ConsentRequested extends ConsentEvent {
  const ConsentRequested();
}

/// The user taps the checkbox.
class ConsentToggled extends ConsentEvent {
  const ConsentToggled(this.checked);

  final bool checked;

  @override
  List<Object?> get props => [checked];
}

/// The user taps "Agree and continue".
class ConsentAccepted extends ConsentEvent {
  const ConsentAccepted();
}

enum ConsentStatus { initial, loading, ready, accepted, failure }

class ConsentState extends Equatable {
  const ConsentState({
    this.status = ConsentStatus.initial,
    this.checked = false,
    this.message,
  });

  final ConsentStatus status;

  /// The state of the checkbox. The button stays disabled while it is false.
  final bool checked;

  final String? message;

  ConsentState copyWith({
    ConsentStatus? status,
    bool? checked,
    String? message,
  }) {
    return ConsentState(
      status: status ?? this.status,
      checked: checked ?? this.checked,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, checked, message];
}

/// Holds the state of the agreement screen.
class ConsentBloc extends Bloc<ConsentEvent, ConsentState> {
  ConsentBloc({required this.getConsent, required this.saveConsent})
    : super(const ConsentState()) {
    on<ConsentRequested>(_onRequested);
    on<ConsentToggled>(_onToggled);
    on<ConsentAccepted>(_onAccepted);
  }

  final GetConsent getConsent;
  final SaveConsent saveConsent;

  Future<void> _onRequested(
    ConsentRequested event,
    Emitter<ConsentState> emit,
  ) async {
    emit(state.copyWith(status: ConsentStatus.loading));
    final result = await getConsent(const NoParams());

    emit(
      result.match(
        (failure) => state.copyWith(
          status: ConsentStatus.failure,
          message: failure.message,
        ),
        (record) => record.agreed
            ? state.copyWith(status: ConsentStatus.accepted, checked: true)
            : state.copyWith(status: ConsentStatus.ready),
      ),
    );
  }

  void _onToggled(ConsentToggled event, Emitter<ConsentState> emit) {
    emit(state.copyWith(checked: event.checked));
  }

  Future<void> _onAccepted(
    ConsentAccepted event,
    Emitter<ConsentState> emit,
  ) async {
    // The design disables the button until the box is ticked. This guard keeps
    // the rule true even when an event arrives from somewhere else.
    if (!state.checked) return;

    emit(state.copyWith(status: ConsentStatus.loading, checked: true));
    final record = ConsentRecord(agreed: true, agreedAt: DateTime.now());
    final result = await saveConsent(record);

    emit(
      result.match(
        (failure) => state.copyWith(
          status: ConsentStatus.failure,
          checked: true,
          message: failure.message,
        ),
        (_) => state.copyWith(status: ConsentStatus.accepted, checked: true),
      ),
    );
  }
}
