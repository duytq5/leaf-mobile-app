import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

/// The models open only for a signed-in user: the app asks for Google sign-in
/// right after the agreement screen.
abstract class AuthRepository {
  /// Opens the Cognito managed login (authorization code + PKCE).
  Future<Either<Failure, Unit>> signIn();

  /// Returns an access token with time left, refreshing it when needed.
  ///
  /// An [AuthFailure] means the user must sign in. A [NetworkFailure] means
  /// the phone is offline and the session is kept.
  Future<Either<Failure, String>> accessToken();

  Future<bool> isSignedIn();

  Future<Either<Failure, Unit>> signOut();
}
