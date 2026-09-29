import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// One action of the domain layer.
///
/// A use case returns a [Failure] or a value. It never throws.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// The parameter of a use case that needs no input.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
