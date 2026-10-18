import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/leaf_model.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/scan_result.dart';
import 'package:leaf_disease_mobile/features/scan/presentation/pages/result_page.dart';

import '../../../../support/model_fixtures.dart';
import '../../../../support/phone_frame.dart';
import '../../../../support/scan_fixtures.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    ScanResult? result,
    VoidCallback? onContinue,
    LeafModel? model,
    bool signedIn = false,
    int pending = 0,
    VoidCallback? onSignIn,
  }) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ResultPage(
          result: result ?? coffeeScan(),
          model: model ?? coffeeModel,
          onBack: () {},
          onContinue: onContinue ?? () {},
          signedIn: signedIn,
          pending: pending,
          onSignIn: onSignIn ?? () {},
        ),
      ),
    );
  }

  testWidgets('shows the top label and its percentage', (tester) async {
    await pump(tester);

    expect(find.text('Result'), findsOneWidget);
    expect(find.text('Predicted label'), findsOneWidget);
    expect(find.text('coffee___rust'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
  });

  testWidgets('names the model and the version', (tester) async {
    await pump(tester);

    expect(find.text('Coffee Leaf model · fold-1-best'), findsOneWidget);
  });

  testWidgets('hides the other scores until the user asks', (tester) async {
    await pump(tester);

    // The design shows one label. The panel stays shut at rest.
    expect(find.text('Show all scores'), findsOneWidget);
    expect(find.textContaining('entropy'), findsNothing);
    expect(find.text('coffee___healthy'), findsNothing);
  });

  testWidgets('shows every score and every metric when opened', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Show all scores'));
    await tester.pumpAndSettle();

    expect(find.text('coffee___healthy'), findsOneWidget);
    expect(find.text('coffee___red_spider_mite'), findsOneWidget);
    expect(find.text('87.0%'), findsOneWidget);
    expect(find.text('latency'), findsOneWidget);
    expect(find.text('entropy'), findsOneWidget);
    expect(find.text('margin'), findsOneWidget);
    expect(find.text('142 ms'), findsOneWidget);
    expect(find.text('Hide all scores'), findsOneWidget);
  });

  testWidgets('opening the scores scrolls them into view', (tester) async {
    // On a phone the panel opens below the fold, behind the Continue block.
    await pump(tester, model: releasedModel);

    await tester.tap(find.text('Show all scores'));
    await tester.pumpAndSettle();

    final list = tester.getRect(find.byType(ListView));
    expect(
      tester.getRect(find.text('margin')).bottom,
      lessThanOrEqualTo(list.bottom),
    );
  });

  testWidgets('shows a scroll bar so the user sees there is more', (
    tester,
  ) async {
    await pump(tester);

    final bar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(bar.thumbVisibility, isTrue);
  });

  testWidgets('shows the labels of the model that ran', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Show all scores'));
    await tester.pumpAndSettle();

    // The design invents four rust levels. The screen shows the three real
    // classes of the trained model.
    expect(find.textContaining('Rust level'), findsNothing);
  });

  testWidgets('Continue reports a tap', (tester) async {
    var continues = 0;
    await pump(tester, onContinue: () => continues++);

    await tester.tap(find.text('Continue'));

    expect(continues, 1);
  });

  testWidgets('offers no label report', (tester) async {
    // Experts label in Label Studio; the app sends only the prediction.
    await pump(tester);

    expect(find.text('Report wrong label'), findsNothing);
  });

  group('sending the photo', () {
    testWidgets('a bundled model offers no sign-in', (tester) async {
      await pump(tester);

      expect(find.text('Sign in to send this photo'), findsNothing);
    });

    testWidgets('a released model asks a signed-out user to sign in', (
      tester,
    ) async {
      var taps = 0;
      await pump(tester, model: releasedModel, onSignIn: () => taps++);

      await tester.tap(find.text('Sign in to send this photo'));

      expect(taps, 1);
    });

    testWidgets('a signed-in user sees what still waits', (tester) async {
      await pump(tester, model: releasedModel, signedIn: true, pending: 2);

      expect(find.text('Sign in to send this photo'), findsNothing);
      expect(
        find.text('2 photos wait. They are sent when the phone is online.'),
        findsOneWidget,
      );
    });

    testWidgets('a signed-in user with nothing waiting is thanked', (
      tester,
    ) async {
      await pump(tester, model: releasedModel, signedIn: true);

      expect(find.text('Photo sent. Thank you for helping.'), findsOneWidget);
    });
  });

  testWidgets('follows a different result', (tester) async {
    await pump(
      tester,
      result: coffeeScan(probabilities: const [0.7, 0.2, 0.1]),
    );

    expect(find.text('coffee___healthy'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
  });
}
