import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Reports whether this phone holds a session.
class IsSignedIn extends UseCase<bool, NoParams> {
  IsSignedIn(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) async =>
      Right(await repository.isSignedIn());
}
