import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_colors.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/core/widgets/screen_scaffold.dart';

void main() {
  test('the theme uses the primary colour of the design', () {
    final theme = AppTheme.light();

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.useMaterial3, isTrue);
  });

  test('the theme names the design font', () {
    expect(AppTheme.light().textTheme.titleMedium?.fontSize, 18);
    expect(AppTheme.fontFamily, 'BeVietnamPro');
  });

  testWidgets('the scaffold bar is 64 pixels high', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ScreenScaffold(
          title: 'New scan',
          onBack: () {},
          body: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('New scan'), findsOneWidget);
    final bar = tester.getSize(
      find.ancestor(of: find.text('New scan'), matching: find.byType(Container)).first,
    );
    expect(bar.height, 64);
  });

  testWidgets('the scaffold hides the back target when asked', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScreenScaffold(title: 'Result', body: SizedBox.shrink()),
      ),
    );

    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('the scaffold reports a back tap', (tester) async {
    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ScreenScaffold(
          title: 'Result',
          onBack: () => backs++,
          body: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));

    expect(backs, 1);
  });
}
