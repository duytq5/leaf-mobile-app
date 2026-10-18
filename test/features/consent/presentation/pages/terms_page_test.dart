import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/features/consent/presentation/pages/terms_page.dart';

import '../../../../support/phone_frame.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const TermsPage()),
    );
  }

  testWidgets('shows a scroll bar so the user sees there is more', (
    tester,
  ) async {
    await pump(tester);

    final bar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(bar.thumbVisibility, isTrue);
  });

  testWidgets('scrolls to the last section', (tester) async {
    await pump(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    final list = tester.getRect(find.byType(ListView));
    final last = find.textContaining('Close the app to stop');
    expect(tester.getRect(last).bottom, lessThanOrEqualTo(list.bottom));
  });
}
