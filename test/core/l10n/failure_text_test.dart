import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/core/l10n/failure_text.dart';
import 'package:leaf_disease_mobile/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));

  test('a coded failure reads its own sentence in each language', () {
    expect(
      vi.failure(
        const AuthFailure('cancelled', code: FailureCode.signInCancelled),
      ),
      'Bạn đã huỷ đăng nhập.',
    );
    expect(
      en.failure(
        const AuthFailure('cancelled', code: FailureCode.signInCancelled),
      ),
      'The sign-in was cancelled.',
    );
  });

  test('every code has a sentence of its own', () {
    for (final l10n in [en, vi]) {
      final sentences = {
        for (final code in FailureCode.values)
          l10n.failure(CacheFailure('x', code: code)),
      };
      expect(sentences, hasLength(FailureCode.values.length));
    }
  });

  test('a failure with no code reads the sentence of its kind', () {
    expect(vi.failure(const NetworkFailure('timeout')), vi.failureNetwork);
    expect(vi.failure(const CacheFailure('disk')), vi.failureStorage);
    expect(vi.failure(const ModelFailure('onnx')), vi.failureModel);
    expect(vi.failure(const ImageFailure('decode')), vi.failureImage);
    expect(vi.failure(const PermissionFailure('denied')), vi.failurePermission);
    expect(vi.failure(const AuthFailure('refused')), vi.failureAuth);
    expect(vi.failure(const QuotaFailure('limit')), vi.failureQuotaReached);
  });

  test('a technical message never reaches the user', () {
    expect(
      en.failure(const ModelFailure('the model does not run: OrtException')),
      isNot(contains('OrtException')),
    );
  });
}
