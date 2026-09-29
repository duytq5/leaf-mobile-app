import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_colors.dart';
import 'package:leaf_disease_mobile/core/widgets/primary_button.dart';

Widget host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('PrimaryButton', () {
    testWidgets('is 56 pixels high', (tester) async {
      await tester.pumpWidget(
        host(PrimaryButton(label: 'Continue', onPressed: () {})),
      );

      expect(tester.getSize(find.byType(PrimaryButton)).height, 56);
    });

    testWidgets('reports a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(PrimaryButton(label: 'Continue', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Continue'));

      expect(taps, 1);
    });

    testWidgets('a null callback disables the button', (tester) async {
      await tester.pumpWidget(
        host(const PrimaryButton(label: 'Continue', onPressed: null)),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows an icon when one is given', (tester) async {
      await tester.pumpWidget(
        host(
          PrimaryButton(
            label: 'Take photo',
            icon: Icons.photo_camera_outlined,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
      expect(find.text('Take photo'), findsOneWidget);
    });
  });

  group('SecondaryButton', () {
    testWidgets('is 56 pixels high', (tester) async {
      await tester.pumpWidget(
        host(SecondaryButton(label: 'Library', onPressed: () {})),
      );

      expect(tester.getSize(find.byType(SecondaryButton)).height, 56);
    });

    testWidgets('reports a tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(SecondaryButton(label: 'Library', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Library'));

      expect(taps, 1);
    });
  });

  group('the design tokens', () {
    test('hold the colours of the artboards', () {
      expect(AppColors.primary, const Color(0xFF1558B0));
      expect(AppColors.primaryDark, const Color(0xFF0B3A75));
      expect(AppColors.tint, const Color(0xFFEAF1FB));
      expect(AppColors.ground, const Color(0xFFF4F7FB));
      expect(AppColors.text, const Color(0xFF122033));
      expect(AppColors.muted, const Color(0xFF4F5F78));
      expect(AppColors.border, const Color(0xFFD5E0EE));
      expect(AppColors.divider, const Color(0xFFE3EAF3));
    });
  });
}
