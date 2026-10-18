import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/core/usecase/usecase.dart';
import 'package:leaf_disease_mobile/features/auth/domain/usecases/is_signed_in.dart';
import 'package:leaf_disease_mobile/features/auth/domain/usecases/sign_in.dart';
import 'package:leaf_disease_mobile/features/outbox/domain/repositories/outbox_repository.dart';
import 'package:leaf_disease_mobile/features/outbox/domain/usecases/outbox_usecases.dart';
import 'package:leaf_disease_mobile/features/outbox/presentation/bloc/outbox_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/model_fixtures.dart';
import '../../../support/scan_fixtures.dart';

class MockQueue extends Mock implements QueueScan {}

class MockSend extends Mock implements SendQueuedScans {}

class MockCount extends Mock implements CountQueuedScans {}

class MockSignIn extends Mock implements SignIn {}

class MockIsSignedIn extends Mock implements IsSignedIn {}

void main() {
  late MockQueue queue;
  late MockSend send;
  late MockCount count;
  late MockSignIn signIn;
  late MockIsSignedIn isSignedIn;
  late StreamController<void> online;
  var pending = 0;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      QueueScanParams(result: coffeeScan(), model: releasedModel),
    );
  });

  setUp(() {
    queue = MockQueue();
    send = MockSend();
    count = MockCount();
    signIn = MockSignIn();
    isSignedIn = MockIsSignedIn();
    online = StreamController<void>.broadcast();
    pending = 0;
    when(() => count(any())).thenAnswer((_) async => Right(pending));
    when(() => count.onlineAgain).thenAnswer((_) => online.stream);
    when(() => queue(any())).thenAnswer((_) async {
      pending++;
      return const Right(unit);
    });
    when(() => send(any())).thenAnswer((_) async {
      final sent = pending;
      pending = 0;
      return Right(OutboxReport(sent: sent));
    });
    when(() => isSignedIn(any())).thenAnswer((_) async => const Right(true));
  });

  tearDown(() => online.close());

  OutboxBloc build() => OutboxBloc(
    queueScan: queue,
    sendQueuedScans: send,
    countQueuedScans: count,
    signIn: signIn,
    isSignedIn: isSignedIn,
  );

  blocTest<OutboxBloc, OutboxState>(
    'on start a signed-in user sends what waits',
    setUp: () => pending = 2,
    build: build,
    act: (bloc) => bloc.add(const OutboxStarted()),
    expect: () => [
      const OutboxState(ready: true, signedIn: true, pending: 2),
      const OutboxState(ready: true, signedIn: true, pending: 2, sending: true),
      const OutboxState(ready: true, signedIn: true),
    ],
  );

  blocTest<OutboxBloc, OutboxState>(
    'a queued scan of a signed-out user waits',
    setUp: () =>
        when(() => isSignedIn(any()))
            .thenAnswer((_) async => const Right(false)),
    build: build,
    act: (bloc) async {
      bloc.add(const OutboxStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(OutboxScanQueued(result: coffeeScan(), model: releasedModel));
    },
    expect: () => [
      const OutboxState(ready: true),
      const OutboxState(ready: true, pending: 1),
    ],
    verify: (_) => verifyNever(() => send(any())),
  );

  blocTest<OutboxBloc, OutboxState>(
    'on start a signed-out user is ready to sign in',
    setUp: () =>
        when(() => isSignedIn(any()))
            .thenAnswer((_) async => const Right(false)),
    build: build,
    act: (bloc) => bloc.add(const OutboxStarted()),
    expect: () => [const OutboxState(ready: true)],
  );

  blocTest<OutboxBloc, OutboxState>(
    'a second tap while signing in is ignored',
    setUp: () => when(() => signIn(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      return const Right(unit);
    }),
    build: build,
    act: (bloc) => bloc
      ..add(const OutboxSignInRequested())
      ..add(const OutboxSignInRequested()),
    wait: const Duration(milliseconds: 20),
    verify: (_) => verify(() => signIn(any())).called(1),
  );

  blocTest<OutboxBloc, OutboxState>(
    'a scan of a bundled model is not counted',
    setUp: () =>
        when(() => queue(any()))
            .thenAnswer((_) async => const Left(ModelFailure('bundled'))),
    build: build,
    act: (bloc) =>
        bloc.add(OutboxScanQueued(result: coffeeScan(), model: coffeeModel)),
    expect: () => <OutboxState>[],
  );

  blocTest<OutboxBloc, OutboxState>(
    'signing in sends what waits',
    setUp: () {
      pending = 1;
      when(() => isSignedIn(any())).thenAnswer((_) async => const Right(false));
      when(() => signIn(any())).thenAnswer((_) async => const Right(unit));
    },
    build: build,
    seed: () => const OutboxState(pending: 1),
    act: (bloc) => bloc.add(const OutboxSignInRequested()),
    expect: () => [
      const OutboxState(pending: 1, signingIn: true),
      const OutboxState(signedIn: true, pending: 1),
      const OutboxState(signedIn: true, pending: 1, sending: true),
      const OutboxState(signedIn: true),
    ],
  );

  blocTest<OutboxBloc, OutboxState>(
    'a cancelled sign-in says why',
    setUp: () =>
        when(() => signIn(any()))
            .thenAnswer((_) async => const Left(AuthFailure('cancelled'))),
    build: build,
    act: (bloc) => bloc.add(const OutboxSignInRequested()),
    expect: () => [
      const OutboxState(signingIn: true),
      const OutboxState(message: 'cancelled'),
    ],
  );

  blocTest<OutboxBloc, OutboxState>(
    'a refused token signs the user out and keeps the scans',
    setUp: () {
      pending = 1;
      when(() => send(any()))
          .thenAnswer((_) async => const Left(AuthFailure('sign in again')));
    },
    build: build,
    seed: () => const OutboxState(signedIn: true, pending: 1),
    act: (bloc) => bloc.add(const OutboxSendRequested()),
    expect: () => [
      const OutboxState(signedIn: true, pending: 1, sending: true),
      const OutboxState(pending: 1, message: 'sign in again'),
    ],
  );

  blocTest<OutboxBloc, OutboxState>(
    'the network coming back sends what waits',
    setUp: () => pending = 1,
    build: build,
    seed: () => const OutboxState(signedIn: true, pending: 1),
    act: (bloc) async {
      bloc.add(const OutboxStarted());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      pending = 3;
      online.add(null);
    },
    wait: const Duration(milliseconds: 10),
    verify: (_) => verify(() => send(any())).called(2),
  );
}
