import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Returns an access token for the Edge API, refreshed when needed.
class GetAccessToken extends UseCase<String, NoParams> {
  GetAccessToken(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, String>> call(NoParams params) => repository.accessToken();
}
