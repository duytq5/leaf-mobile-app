import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/core/usecase/usecase.dart';

class _Echo extends UseCase<String, String> {
  @override
  Future<Either<Failure, String>> call(String params) async => Right(params);
}

class _Broken extends UseCase<String, NoParams> {
  @override
  Future<Either<Failure, String>> call(NoParams params) async =>
      const Left(CacheFailure('no store'));
}

void main() {
  test('a use case returns Right for a good call', () async {
    final result = await _Echo()('hello');

    expect(result.getRight().toNullable(), 'hello');
  });

  test('a use case returns Left for a failure', () async {
    final result = await _Broken()(const NoParams());

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), const CacheFailure('no store'));
  });

  test('two failures with the same message are equal', () {
    expect(const CacheFailure('x'), const CacheFailure('x'));
  });

  test('two failure types with the same message are different', () {
    expect(const CacheFailure('x') == const ModelFailure('x'), isFalse);
  });

  test('a failure carries its message', () {
    expect(const ImageFailure('no image').message, 'no image');
  });

  test('NoParams instances are equal', () {
    expect(const NoParams(), const NoParams());
  });
}
