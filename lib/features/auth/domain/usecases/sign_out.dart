import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Forgets the session on this phone.
class SignOut extends UseCase<Unit, NoParams> {
  SignOut(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => repository.signOut();
}
