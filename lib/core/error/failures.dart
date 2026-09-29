import 'package:equatable/equatable.dart';

/// The base of every error that crosses a layer boundary.
///
/// The domain layer returns a [Failure] on the left of an `Either`. It never
/// throws an exception to the presentation layer.
abstract class Failure extends Equatable {
  const Failure(this.message);

  /// A sentence for the user. It does not hold a stack trace.
  final String message;

  @override
  List<Object?> get props => [message, runtimeType];
}

/// The device store does not answer.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// The model does not load or does not run.
class ModelFailure extends Failure {
  const ModelFailure(super.message);
}

/// The image does not decode, or the user selects no image.
class ImageFailure extends Failure {
  const ImageFailure(super.message);
}

/// The user refuses the camera or the photo library.
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
