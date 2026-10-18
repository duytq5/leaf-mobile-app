import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/features/auth/presentation/pages/sign_in_page.dart';

import '../../../../support/phone_frame.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool busy = false,
    VoidCallback? onSignIn,
  }) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: SignInPage(busy: busy, onSignIn: onSignIn ?? () {}),
      ),
    );
  }

  testWidgets('asks the user to sign in with Google', (tester) async {
    await pump(tester);

    expect(find.text('Sign in to LeafScan'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('offers no way past it without an account', (tester) async {
    await pump(tester);

    expect(find.textContaining('without'), findsNothing);
    expect(find.textContaining('Skip'), findsNothing);
  });

  testWidgets('the button starts the sign-in', (tester) async {
    var taps = 0;
    await pump(tester, onSignIn: () => taps++);

    await tester.tap(find.text('Sign in with Google'));

    expect(taps, 1);
  });

  testWidgets('the button waits while the browser is open', (tester) async {
    var taps = 0;
    await pump(tester, busy: true, onSignIn: () => taps++);

    await tester.tap(find.text('Sign in with Google'), warnIfMissed: false);

    expect(taps, 0);
  });
}
