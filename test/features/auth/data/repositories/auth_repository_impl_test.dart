import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/error/api_exception.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/features/auth/data/datasources/browser_auth_data_source.dart';
import 'package:leaf_disease_mobile/features/auth/data/datasources/cognito_auth_data_source.dart';
import 'package:leaf_disease_mobile/features/auth/data/datasources/token_store.dart';
import 'package:leaf_disease_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockCognito extends Mock implements CognitoAuthDataSource {}

class MockBrowser extends Mock implements BrowserAuthDataSource {}

class MockStore extends Mock implements TokenStore {}

const _settings = CognitoSettings(
  domain: 'd.example',
  clientId: 'client123',
  redirectUri: 'leafal://auth/callback',
);

final _now = DateTime.utc(2026, 10, 14, 12);

void main() {
  late MockCognito cognito;
  late MockBrowser browser;
  late MockStore store;
  late AuthRepositoryImpl repository;
  late String sentState;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(
      StoredSession(accessToken: 'a', refreshToken: 'r', expiresAt: _now),
    );
  });

  AuthRepositoryImpl build(CognitoSettings settings) => AuthRepositoryImpl(
    cognito: cognito,
    browser: browser,
    store: store,
    settings: settings,
    clock: () => _now,
  );

  setUp(() {
    cognito = MockCognito();
    browser = MockBrowser();
    store = MockStore();
    repository = build(_settings);
    when(() => store.write(any())).thenAnswer((_) async {});
    when(() => store.clear()).thenAnswer((_) async {});
    when(
      () => cognito.authorizeUrl(
        state: any(named: 'state'),
        challenge: any(named: 'challenge'),
      ),
    ).thenAnswer((call) {
      sentState = call.namedArguments[#state] as String;
      return Uri.parse('https://d.example/oauth2/authorize');
    });
  });

  group('signIn', () {
    void givenCallback(String Function() url) {
      when(() => browser.authenticate(any(), any()))
          .thenAnswer((_) async => Uri.parse(url()));
    }

    test('exchanges the code and stores the session', () async {
      givenCallback(() => 'leafal://auth/callback?code=abc&state=$sentState');
      when(
        () => cognito.exchangeCode(
          code: 'abc',
          verifier: any(named: 'verifier'),
        ),
      ).thenAnswer(
        (_) async => const TokenResponse(
          accessToken: 'at',
          refreshToken: 'rt',
          expiresIn: Duration(hours: 1),
        ),
      );

      final result = await repository.signIn();

      expect(result.isRight(), isTrue);
      verify(() => browser.authenticate(any(), 'leafal')).called(1);
      final saved =
          verify(() => store.write(captureAny())).captured.single
              as StoredSession;
      expect(saved.accessToken, 'at');
      expect(saved.refreshToken, 'rt');
      expect(saved.expiresAt, _now.add(const Duration(hours: 1)));
    });

    test('a callback with another state is refused', () async {
      givenCallback(() => 'leafal://auth/callback?code=abc&state=forged');

      final result = await repository.signIn();

      expect(
        result.getLeft().toNullable(),
        isA<AuthFailure>().having((f) => f.code, 'code', FailureCode.signInUnfinished),
      );
      verifyNever(
        () => cognito.exchangeCode(
          code: any(named: 'code'),
          verifier: any(named: 'verifier'),
        ),
      );
    });

    test('a closed browser is an AuthFailure', () async {
      when(() => browser.authenticate(any(), any()))
          .thenThrow(Exception('CANCELED'));

      final result = await repository.signIn();

      expect(
        result.getLeft().toNullable(),
        isA<AuthFailure>().having((f) => f.code, 'code', FailureCode.signInCancelled),
      );
    });

    test('a build without a client id cannot sign in', () async {
      final result = await build(
        const CognitoSettings(
          domain: 'd.example',
          clientId: '',
          redirectUri: 'leafal://auth/callback',
        ),
      ).signIn();

      expect(
        result.getLeft().toNullable(),
        isA<AuthFailure>().having((f) => f.code, 'code', FailureCode.signInNotSetUp),
      );
      verifyNever(() => browser.authenticate(any(), any()));
    });
  });

  group('accessToken', () {
    test('signed out is an AuthFailure', () async {
      when(() => store.read()).thenAnswer((_) async => null);

      final result = await repository.accessToken();

      expect(
        result.getLeft().toNullable(),
        isA<AuthFailure>().having((f) => f.code, 'code', FailureCode.signInNeeded),
      );
    });

    test('a token with time left is returned as it is', () async {
      when(() => store.read()).thenAnswer(
        (_) async => StoredSession(
          accessToken: 'at',
          refreshToken: 'rt',
          expiresAt: _now.add(const Duration(minutes: 10)),
        ),
      );

      expect((await repository.accessToken()).getRight().toNullable(), 'at');
      verifyNever(() => cognito.refresh(any()));
    });

    test('a token about to expire is refreshed and stored', () async {
      when(() => store.read()).thenAnswer(
        (_) async => StoredSession(
          accessToken: 'old',
          refreshToken: 'rt',
          expiresAt: _now.add(const Duration(seconds: 30)),
        ),
      );
      when(() => cognito.refresh('rt')).thenAnswer(
        (_) async => const TokenResponse(
          accessToken: 'new',
          expiresIn: Duration(hours: 1),
        ),
      );

      final result = await repository.accessToken();

      expect(result.getRight().toNullable(), 'new');
      final saved =
          verify(() => store.write(captureAny())).captured.single
              as StoredSession;
      expect(saved.refreshToken, 'rt');
    });

    test('a refused refresh signs the user out', () async {
      when(() => store.read()).thenAnswer(
        (_) async => StoredSession(
          accessToken: 'old',
          refreshToken: 'rt',
          expiresAt: _now,
        ),
      );
      when(() => cognito.refresh('rt')).thenThrow(
        const ApiException(status: 400, code: 'invalid_grant', message: 'no'),
      );

      final result = await repository.accessToken();

      expect(
        result.getLeft().toNullable(),
        isA<AuthFailure>().having((f) => f.code, 'code', FailureCode.signInExpired),
      );
      verify(() => store.clear()).called(1);
    });

    test('offline keeps the session and is a NetworkFailure', () async {
      when(() => store.read()).thenAnswer(
        (_) async => StoredSession(
          accessToken: 'old',
          refreshToken: 'rt',
          expiresAt: _now,
        ),
      );
      when(() => cognito.refresh('rt'))
          .thenThrow(const ApiException.offline('no network'));

      final result = await repository.accessToken();

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
      verifyNever(() => store.clear());
    });
  });

  test('signOut forgets the session', () async {
    final result = await repository.signOut();

    expect(result.isRight(), isTrue);
    verify(() => store.clear()).called(1);
  });

  group('isSignedIn', () {
    StoredSession session(DateTime expiresAt) => StoredSession(
      accessToken: 'a',
      refreshToken: 'rt',
      expiresAt: expiresAt,
    );

    test('no stored session is signed out', () async {
      when(() => store.read()).thenAnswer((_) async => null);

      expect(await repository.isSignedIn(), isFalse);
    });

    test('a live token is signed in without a refresh', () async {
      when(() => store.read())
          .thenAnswer((_) async => session(_now.add(const Duration(hours: 1))));

      expect(await repository.isSignedIn(), isTrue);
      verifyNever(() => cognito.refresh(any()));
    });

    test('an expired token that refreshes is signed in', () async {
      when(() => store.read()).thenAnswer((_) async => session(_now));
      when(() => cognito.refresh('rt')).thenAnswer(
        (_) async => const TokenResponse(
          accessToken: 'new',
          expiresIn: Duration(hours: 1),
        ),
      );

      expect(await repository.isSignedIn(), isTrue);
    });

    test('a refused refresh is signed out, so the app asks again', () async {
      when(() => store.read()).thenAnswer((_) async => session(_now));
      when(() => cognito.refresh('rt')).thenThrow(
        const ApiException(status: 400, code: 'invalid_grant', message: 'no'),
      );

      expect(await repository.isSignedIn(), isFalse);
      verify(() => store.clear()).called(1);
    });

    test('offline keeps the stored session signed in', () async {
      when(() => store.read()).thenAnswer((_) async => session(_now));
      when(() => cognito.refresh('rt'))
          .thenThrow(const ApiException.offline('no network'));

      expect(await repository.isSignedIn(), isTrue);
      verifyNever(() => store.clear());
    });
  });
}
