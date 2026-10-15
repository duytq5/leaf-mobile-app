import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

/// "Sign in to contribute": the app works without an account, and only an
/// upload needs one (design doc, change 15).
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
