import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/core/widgets/primary_button.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/leaf_model.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/label_correction.dart';
import 'package:leaf_disease_mobile/features/scan/presentation/bloc/correction_bloc.dart';
import 'package:leaf_disease_mobile/features/scan/presentation/pages/report_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/model_fixtures.dart';
import '../../../../support/phone_frame.dart';
import '../../../../support/scan_fixtures.dart';

class MockCorrectionBloc
    extends MockBloc<CorrectionEvent, CorrectionState>
    implements CorrectionBloc {}

void main() {
  late MockCorrectionBloc bloc;

  setUpAll(() => registerFallbackValue(const CorrectionSubmitted()));

  setUp(() => bloc = MockCorrectionBloc());

  Future<void> pump(
    WidgetTester tester, {
    required CorrectionState state,
    LeafModel? model,
    VoidCallback? onSubmitted,
  }) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    final chosen = model ?? coffeeModel;
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.result).thenReturn(coffeeScan());
    when(() => bloc.model).thenReturn(chosen);
    when(() => bloc.choices)
        .thenReturn([...chosen.labels, LabelCorrection.notSure]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<CorrectionBloc>.value(
          value: bloc,
          child: ReportPage(
            onBack: () {},
            onSubmitted: onSubmitted ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows the predicted label with a line through it',
      (tester) async {
    await pump(tester, state: const CorrectionState());

    expect(find.text('Report wrong label'), findsOneWidget);
    expect(find.text('AI predicted'), findsOneWidget);
    expect(find.text('coffee___rust'), findsWidgets);
  });

  testWidgets('shows one row per label of the model plus an escape row',
      (tester) async {
    await pump(tester, state: const CorrectionState());

    // The coffee model has 3 classes, so the screen shows 4 rows. The design
    // canvas draws 6 rows with four rust levels the model does not have.
    expect(find.byType(Radio<String>), findsNWidgets(4));
    expect(find.text('Not sure / other'), findsOneWidget);
    expect(find.textContaining('Rust level'), findsNothing);
  });

  testWidgets('shows seven rows for the durian model', (tester) async {
    await pump(tester, state: const CorrectionState(), model: durianModel);

    expect(find.byType(Radio<String>), findsNWidgets(7));
    for (final label in durianModel.labels) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('disables the button until the user chooses', (tester) async {
    await pump(tester, state: const CorrectionState());

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('enables the button after a choice', (tester) async {
    await pump(
      tester,
      state: const CorrectionState(chosen: 'coffee___healthy'),
    );

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('a tap on a row sends the chosen label', (tester) async {
    await pump(tester, state: const CorrectionState());

    await tester.tap(find.text('coffee___healthy'));

    verify(() => bloc.add(const CorrectionLabelChosen('coffee___healthy')))
        .called(1);
  });

  testWidgets('the button sends the submit event', (tester) async {
    await pump(
      tester,
      state: const CorrectionState(chosen: 'coffee___healthy'),
    );

    await tester.tap(find.text('Submit correction'));

    verify(() => bloc.add(const CorrectionSubmitted())).called(1);
  });

  testWidgets('runs the callback when the correction is stored',
      (tester) async {
    var done = 0;
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    when(() => bloc.result).thenReturn(coffeeScan());
    when(() => bloc.model).thenReturn(coffeeModel);
    when(() => bloc.choices)
        .thenReturn([...coffeeModel.labels, LabelCorrection.notSure]);
    whenListen(
      bloc,
      Stream.fromIterable(const [
        CorrectionState(
          status: CorrectionStatus.saved,
          chosen: 'coffee___healthy',
        ),
      ]),
      initialState: const CorrectionState(chosen: 'coffee___healthy'),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<CorrectionBloc>.value(
          value: bloc,
          child: ReportPage(onBack: () {}, onSubmitted: () => done++),
        ),
      ),
    );
    await tester.pump();

    expect(done, 1);
  });
}
