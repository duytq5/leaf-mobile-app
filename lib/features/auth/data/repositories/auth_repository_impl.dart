import 'package:fpdart/fpdart.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/browser_auth_data_source.dart';
import '../datasources/cognito_auth_data_source.dart';
import '../datasources/pkce.dart';
import '../datasources/token_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.cognito,
    required this.browser,
    required this.store,
    required this.settings,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// A token with less time left than this is refreshed before use.
  static const refreshMargin = Duration(minutes: 1);

  final CognitoAuthDataSource cognito;
  final BrowserAuthDataSource browser;
  final TokenStore store;
  final CognitoSettings settings;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, Unit>> signIn() async {
    if (!settings.configured) {
      return const Left(AuthFailure('sign-in is not set up in this build'));
    }

    final pkce = Pkce.generate();
    final state = Pkce.state();
    final Uri callback;
    try {
      callback = await browser.authenticate(
        cognito.authorizeUrl(state: state, challenge: pkce.challenge),
        settings.callbackScheme,
      );
    } catch (_) {
      return const Left(AuthFailure('the sign-in was cancelled'));
    }

    final code = callback.queryParameters['code'];
    if (callback.queryParameters['state'] != state || code == null) {
      return const Left(AuthFailure('the sign-in did not finish'));
    }

    try {
      final tokens = await cognito.exchangeCode(
        code: code,
        verifier: pkce.verifier,
      );
      await store.write(
        StoredSession(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken!,
          expiresAt: _clock().add(tokens.expiresIn),
        ),
      );
      return const Right(unit);
    } on ApiException catch (error) {
      return Left(
        error.offline
            ? NetworkFailure(error.message)
            : AuthFailure(error.message),
      );
    }
  }

  @override
  Future<Either<Failure, String>> accessToken() async {
    final session = await store.read();
    if (session == null) {
      return const Left(AuthFailure('sign in to send photos'));
    }
    if (session.expiresAt.isAfter(_clock().add(refreshMargin))) {
      return Right(session.accessToken);
    }

    try {
      final tokens = await cognito.refresh(session.refreshToken);
      await store.write(
        StoredSession(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken ?? session.refreshToken,
          expiresAt: _clock().add(tokens.expiresIn),
        ),
      );
      return Right(tokens.accessToken);
    } on ApiException catch (error) {
      if (error.offline || (error.status ?? 0) >= 500) {
        return Left(NetworkFailure(error.message));
      }
      // The refresh token expired or the user was disabled.
      await store.clear();
      return const Left(AuthFailure('sign in again to send photos'));
    }
  }

  @override
  Future<bool> isSignedIn() async => await store.read() != null;

  @override
  Future<Either<Failure, Unit>> signOut() async {
    await store.clear();
    return const Right(unit);
  }
}
