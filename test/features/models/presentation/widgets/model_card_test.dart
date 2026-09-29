import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/features/models/presentation/widgets/model_card.dart';

import '../../../../support/model_fixtures.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool selected,
    VoidCallback? onTap,
    bool durian = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ModelCard(
            model: durian ? durianModel : coffeeModel,
            selected: selected,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows the name and the subtitle from the manifest',
      (tester) async {
    await pump(tester, selected: true);

    expect(find.text('Coffee Leaf'), findsOneWidget);
    expect(find.text('RoCoLe · fold-1-best · 3 labels'), findsOneWidget);
  });

  testWidgets('shows one chip per label of the model', (tester) async {
    await pump(tester, selected: true);

    // The trained coffee model has 3 classes. The design canvas shows 6 chips
    // and says 7 labels. The card follows the manifest, not the design.
    expect(find.text('coffee___healthy'), findsOneWidget);
    expect(find.text('coffee___red_spider_mite'), findsOneWidget);
    expect(find.text('coffee___rust'), findsOneWidget);
    expect(find.textContaining('Rust level'), findsNothing);
  });

  testWidgets('shows six chips for the durian model', (tester) async {
    await pump(tester, selected: false, durian: true);

    expect(find.text('Vietnamese durian · fold-3-best · 6 labels'),
        findsOneWidget);
    for (final label in durianModel.labels) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('shows a check mark only when selected', (tester) async {
    await pump(tester, selected: false);
    expect(find.byIcon(Icons.check), findsNothing);

    await pump(tester, selected: true);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('reports a tap', (tester) async {
    var taps = 0;
    await pump(tester, selected: false, onTap: () => taps++);

    await tester.tap(find.byType(ModelCard));

    expect(taps, 1);
  });
}
