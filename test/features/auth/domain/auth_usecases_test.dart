import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:leaf_disease_mobile/core/usecase/usecase.dart';
import 'package:leaf_disease_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:leaf_disease_mobile/features/auth/domain/usecases/get_access_token.dart';
import 'package:leaf_disease_mobile/features/auth/domain/usecases/sign_in.dart';
import 'package:leaf_disease_mobile/features/auth/domain/usecases/sign_out.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements AuthRepository {}

void main() {
  late MockAuth auth;

  setUp(() => auth = MockAuth());

  test('SignIn calls the repository', () async {
    when(() => auth.signIn()).thenAnswer((_) async => const Right(unit));

    expect((await SignIn(auth)(const NoParams())).isRight(), isTrue);
  });

  test('SignOut calls the repository', () async {
    when(() => auth.signOut()).thenAnswer((_) async => const Right(unit));

    expect((await SignOut(auth)(const NoParams())).isRight(), isTrue);
  });

  test('GetAccessToken returns the token', () async {
    when(() => auth.accessToken()).thenAnswer((_) async => const Right('at'));

    expect(
      (await GetAccessToken(auth)(const NoParams())).getRight().toNullable(),
      'at',
    );
  });
}
