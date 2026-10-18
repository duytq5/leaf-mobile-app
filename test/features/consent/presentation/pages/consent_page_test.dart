import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/core/widgets/primary_button.dart';
import 'package:leaf_disease_mobile/features/consent/presentation/bloc/consent_bloc.dart';
import 'package:leaf_disease_mobile/features/consent/presentation/pages/consent_page.dart';
import 'package:leaf_disease_mobile/features/consent/presentation/pages/terms_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/phone_frame.dart';

class MockConsentBloc extends MockBloc<ConsentEvent, ConsentState>
    implements ConsentBloc {}

void main() {
  late MockConsentBloc bloc;

  setUpAll(() => registerFallbackValue(const ConsentRequested()));

  setUp(() => bloc = MockConsentBloc());

  Future<void> pump(
    WidgetTester tester, {
    required ConsentState state,
    VoidCallback? onAccepted,
  }) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<ConsentBloc>.value(
          value: bloc,
          child: ConsentPage(onAccepted: onAccepted ?? () {}),
        ),
      ),
    );
  }

  testWidgets('shows the title and the three facts', (tester) async {
    await pump(tester, state: const ConsentState(status: ConsentStatus.ready));

    expect(find.text('Before you start'), findsOneWidget);
    expect(find.text('Photos are uploaded'), findsOneWidget);
    expect(find.text('Used to train AI'), findsOneWidget);
    expect(find.text('Sent when you are online'), findsOneWidget);
    // The app has no label report any more.
    expect(find.textContaining('correction'), findsNothing);
  });

  testWidgets('disables the button while the checkbox is clear', (tester) async {
    await pump(tester, state: const ConsentState(status: ConsentStatus.ready));

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
    expect(button.label, 'Agree & continue');
  });

  testWidgets('enables the button when the checkbox is ticked', (tester) async {
    await pump(
      tester,
      state: const ConsentState(status: ConsentStatus.ready, checked: true),
    );

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('a tap on the checkbox sends ConsentToggled', (tester) async {
    await pump(tester, state: const ConsentState(status: ConsentStatus.ready));

    await tester.tap(find.byType(Checkbox));

    verify(() => bloc.add(const ConsentToggled(true))).called(1);
  });

  testWidgets('a tap on the button sends ConsentAccepted', (tester) async {
    await pump(
      tester,
      state: const ConsentState(status: ConsentStatus.ready, checked: true),
    );

    await tester.tap(find.text('Agree & continue'));

    verify(() => bloc.add(const ConsentAccepted())).called(1);
  });

  testWidgets('opens the terms screen', (tester) async {
    await pump(tester, state: const ConsentState(status: ConsentStatus.ready));

    await tester.scrollUntilVisible(
      find.text('Read full terms'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Read full terms'));
    await tester.pumpAndSettle();

    expect(find.byType(TermsPage), findsOneWidget);
    expect(find.text('Full terms'), findsOneWidget);
  });

  testWidgets('runs the callback when the state becomes accepted',
      (tester) async {
    var accepted = 0;
    whenListen(
      bloc,
      Stream.fromIterable(const [
        ConsentState(status: ConsentStatus.accepted, checked: true),
      ]),
      initialState: const ConsentState(status: ConsentStatus.ready),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<ConsentBloc>.value(
          value: bloc,
          child: ConsentPage(onAccepted: () => accepted++),
        ),
      ),
    );
    await tester.pump();

    expect(accepted, 1);
  });

  testWidgets('shows a failure message', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable(const [
        ConsentState(status: ConsentStatus.failure, message: 'no store'),
      ]),
      initialState: const ConsentState(status: ConsentStatus.ready),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<ConsentBloc>.value(
          value: bloc,
          child: ConsentPage(onAccepted: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('no store'), findsOneWidget);
  });
}
