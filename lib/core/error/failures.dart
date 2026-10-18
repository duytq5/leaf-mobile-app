import 'package:equatable/equatable.dart';

/// The base of every error that crosses a layer boundary.
///
/// The domain layer returns a [Failure] on the left of an `Either`. It never
/// throws an exception to the presentation layer.
abstract class Failure extends Equatable {
  const Failure(this.message, {this.code});

  /// What went wrong, in English, for a developer. A screen shows the
  /// translated sentence of [code] instead.
  final String message;

  /// The case the user needs to hear about. A null code means the screen shows
  /// the general sentence of the failure's kind.
  final FailureCode? code;

  @override
  List<Object?> get props => [message, code, runtimeType];
}

/// The cases a screen names in its own sentence.
enum FailureCode {
  signInNotSetUp,
  signInCancelled,
  signInUnfinished,
  signInRefused,
  signInNeeded,
  signInExpired,
  catalogOffline,
  catalogUnreadable,
  modelNotReleased,
  downloadDamaged,
  downloadOffline,
  downloadFailed,
  photoTooLarge,
}

/// The device store does not answer.
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// The model does not load or does not run.
class ModelFailure extends Failure {
  const ModelFailure(super.message, {super.code});
}

/// The image does not decode, or the user selects no image.
class ImageFailure extends Failure {
  const ImageFailure(super.message, {super.code});
}

/// The user refuses the camera or the photo library.
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

/// The user is not signed in, or the sign-in did not finish.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// The phone is offline or the server does not answer.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// The user sent the daily number of photos the platform allows.
class QuotaFailure extends Failure {
  const QuotaFailure(super.message, {this.retryAfter, super.code});

  final Duration? retryAfter;
}
