import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/features/auth/presentation/pages/sign_in_page.dart';
import 'package:leaf_disease_mobile/features/consent/presentation/pages/terms_page.dart';
import 'package:leaf_disease_mobile/features/scan/presentation/pages/result_page.dart';
import 'package:leaf_disease_mobile/l10n/generated/app_localizations.dart';

import '../support/localized_app.dart';
import '../support/model_fixtures.dart';
import '../support/phone_frame.dart';
import '../support/scan_fixtures.dart';

const _vi = Locale('vi');

void main() {
  testWidgets('the sign-in screen speaks Vietnamese', (tester) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    await tester.pumpWidget(
      localizedApp(SignInPage(busy: false, onSignIn: () {}), locale: _vi),
    );

    expect(find.text('Đăng nhập LeafScan'), findsOneWidget);
    expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
  });

  testWidgets('the terms speak Vietnamese', (tester) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    await tester.pumpWidget(localizedApp(const TermsPage(), locale: _vi));

    expect(find.text('Điều khoản đầy đủ'), findsOneWidget);
    expect(find.text('Ứng dụng gửi những gì'), findsOneWidget);
    expect(find.byTooltip('Quay lại trang đồng ý'), findsOneWidget);
  });

  testWidgets('the result counts the waiting photos in Vietnamese', (
    tester,
  ) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    await tester.pumpWidget(
      localizedApp(
        ResultPage(
          result: coffeeScan(),
          model: releasedModel,
          onBack: () {},
          onContinue: () {},
          signedIn: true,
          pending: 2,
        ),
        locale: _vi,
      ),
    );

    expect(find.text('Kết quả'), findsOneWidget);
    expect(find.text('Nhãn dự đoán'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
    expect(
      find.text('Còn 2 ảnh đang chờ. Ảnh sẽ được gửi khi điện thoại có mạng.'),
      findsOneWidget,
    );
  });

  test('a phone in another language falls back to English', () {
    expect(AppLocalizations.supportedLocales.first, const Locale('en'));
    expect(
      basicLocaleListResolution(const [
        Locale('fr', 'FR'),
      ], AppLocalizations.supportedLocales),
      const Locale('en'),
    );
  });

  test('a Vietnamese phone gets Vietnamese', () {
    expect(
      basicLocaleListResolution(const [
        Locale('vi', 'VN'),
      ], AppLocalizations.supportedLocales),
      const Locale('vi'),
    );
  });
}
