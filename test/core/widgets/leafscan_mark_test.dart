import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_colors.dart';
import 'package:leaf_disease_mobile/core/widgets/leafscan_mark.dart';

void main() {
  testWidgets('the mark takes the size it is given', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: LeafScanMark(size: 64))),
      ),
    );

    expect(tester.getSize(find.byType(LeafScanMark)), const Size(64, 64));
  });

  testWidgets('the tile is square and holds the mark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: LeafScanTile())),
      ),
    );

    // The design draws a 72 pixel tile on the agreement screen.
    expect(tester.getSize(find.byType(LeafScanTile)), const Size(72, 72));
    expect(find.byType(LeafScanMark), findsOneWidget);
  });

  testWidgets('the tile uses the primary colour of the design', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: LeafScanTile(size: 96))),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(LeafScanTile),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.primary);
  });

  testWidgets('the mark paints without an error at a small size',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: LeafScanMark(size: 16))),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
