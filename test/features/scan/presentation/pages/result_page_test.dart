import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
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
    VoidCallback? onReport,
  }) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ResultPage(
          result: result ?? coffeeScan(),
          model: coffeeModel,
          onBack: () {},
          onContinue: onContinue ?? () {},
          onReport: onReport ?? () {},
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

  testWidgets('shows every score and every metric when opened',
      (tester) async {
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

  testWidgets('shows the labels of the model that ran', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Show all scores'));
    await tester.pumpAndSettle();

    // The design invents four rust levels. The screen shows the three real
    // classes of the trained model.
    expect(find.textContaining('Rust level'), findsNothing);
  });

  testWidgets('both actions report a tap', (tester) async {
    var continues = 0;
    var reports = 0;
    await pump(
      tester,
      onContinue: () => continues++,
      onReport: () => reports++,
    );

    await tester.tap(find.text('Continue'));
    await tester.tap(find.text('Report wrong label'));

    expect(continues, 1);
    expect(reports, 1);
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
