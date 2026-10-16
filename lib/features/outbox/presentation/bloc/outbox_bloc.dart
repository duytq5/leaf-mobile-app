import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/is_signed_in.dart';
import '../../../auth/domain/usecases/sign_in.dart';
import '../../../models/domain/entities/leaf_model.dart';
import '../../../scan/domain/entities/scan_result.dart';
import '../../domain/usecases/outbox_usecases.dart';

sealed class OutboxEvent extends Equatable {
  const OutboxEvent();

  @override
  List<Object?> get props => [];
}

/// The app opens. Read the session and the outbox, then send.
class OutboxStarted extends OutboxEvent {
  const OutboxStarted();
}

/// A scan finished. Store it for the platform.
class OutboxScanQueued extends OutboxEvent {
  const OutboxScanQueued({required this.result, required this.model});

  final ScanResult result;
  final LeafModel model;

  @override
  List<Object?> get props => [result, model];
}

/// The user taps "Sign in with Google" or "Sign in to send this photo".
class OutboxSignInRequested extends OutboxEvent {
  const OutboxSignInRequested();
}

/// Try to send now, for example when the network comes back.
class OutboxSendRequested extends OutboxEvent {
  const OutboxSendRequested();
}

class OutboxState extends Equatable {
  const OutboxState({
    this.ready = false,
    this.signedIn = false,
    this.signingIn = false,
    this.pending = 0,
    this.sending = false,
    this.message,
  });

  /// The stored session has been read, so [signedIn] can be trusted.
  final bool ready;

  final bool signedIn;

  /// The sign-in browser is open.
  final bool signingIn;

  /// The scans that wait on this phone.
  final int pending;
  final bool sending;
  final String? message;

  OutboxState copyWith({
    bool? ready,
    bool? signedIn,
    bool? signingIn,
    int? pending,
    bool? sending,
    String? message,
  }) => OutboxState(
    ready: ready ?? this.ready,
    signedIn: signedIn ?? this.signedIn,
    signingIn: signingIn ?? this.signingIn,
    pending: pending ?? this.pending,
    sending: sending ?? this.sending,
    message: message,
  );

  @override
  List<Object?> get props => [
    ready,
    signedIn,
    signingIn,
    pending,
    sending,
    message,
  ];
}

/// Holds the outbox for the whole app: every scan of a released model is
/// stored, and sent when the user is signed in and the phone is online.
class OutboxBloc extends Bloc<OutboxEvent, OutboxState> {
  OutboxBloc({
    required this.queueScan,
    required this.sendQueuedScans,
    required this.countQueuedScans,
    required this.signIn,
    required this.isSignedIn,
  }) : super(const OutboxState()) {
    on<OutboxStarted>(_onStarted);
    on<OutboxScanQueued>(_onQueued);
    on<OutboxSignInRequested>(_onSignIn);
    on<OutboxSendRequested>((_, emit) async {
      emit(state.copyWith(pending: await _count()));
      await _send(emit);
    });
    _online = countQueuedScans.onlineAgain.listen(
      (_) => add(const OutboxSendRequested()),
    );
  }

  final QueueScan queueScan;
  final SendQueuedScans sendQueuedScans;
  final CountQueuedScans countQueuedScans;
  final SignIn signIn;
  final IsSignedIn isSignedIn;
  late final StreamSubscription<void> _online;

  Future<void> _onStarted(
    OutboxStarted event,
    Emitter<OutboxState> emit,
  ) async {
    final signedIn = (await isSignedIn(const NoParams()))
        .getOrElse((_) => false);
    emit(
      state.copyWith(
        ready: true,
        signedIn: signedIn,
        pending: await _count(),
      ),
    );
    await _send(emit);
  }

  Future<void> _onQueued(
    OutboxScanQueued event,
    Emitter<OutboxState> emit,
  ) async {
    final queued = await queueScan(
      QueueScanParams(result: event.result, model: event.model),
    );
    // A bundled model cannot send, so its scan stays on the screen only.
    if (queued.isLeft()) return;

    emit(state.copyWith(pending: await _count()));
    await _send(emit);
  }

  Future<void> _onSignIn(
    OutboxSignInRequested event,
    Emitter<OutboxState> emit,
  ) async {
    if (state.signingIn) return;

    emit(state.copyWith(signingIn: true));
    final result = await signIn(const NoParams());
    if (result.isLeft()) {
      emit(
        state.copyWith(
          signingIn: false,
          message: result.getLeft().toNullable()!.message,
        ),
      );
      return;
    }
    emit(state.copyWith(signedIn: true, signingIn: false));
    await _send(emit);
  }

  Future<void> _send(Emitter<OutboxState> emit) async {
    if (!state.signedIn || state.pending == 0 || state.sending) return;

    emit(state.copyWith(sending: true));
    final result = await sendQueuedScans(const NoParams());
    final pending = await _count();
    result.match(
      (failure) => emit(
        state.copyWith(
          signedIn: failure is AuthFailure ? false : null,
          pending: pending,
          sending: false,
          message: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(pending: pending, sending: false)),
    );
  }

  Future<int> _count() async =>
      (await countQueuedScans(const NoParams()))
          .getOrElse((_) => state.pending);

  @override
  Future<void> close() async {
    await _online.cancel();
    return super.close();
  }
}
