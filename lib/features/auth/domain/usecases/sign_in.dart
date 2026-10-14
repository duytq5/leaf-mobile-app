import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Opens the managed login. The first upload calls it.
class SignIn extends UseCase<Unit, NoParams> {
  SignIn(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => repository.signIn();
}
