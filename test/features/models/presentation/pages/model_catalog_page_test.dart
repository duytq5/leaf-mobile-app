import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/core/widgets/primary_button.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/leaf_model.dart';
import 'package:leaf_disease_mobile/features/models/presentation/bloc/model_catalog_bloc.dart';
import 'package:leaf_disease_mobile/features/models/presentation/pages/model_catalog_page.dart';
import 'package:leaf_disease_mobile/features/models/presentation/widgets/model_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/model_fixtures.dart';
import '../../../../support/phone_frame.dart';

class MockModelCatalogBloc
    extends MockBloc<ModelCatalogEvent, ModelCatalogState>
    implements ModelCatalogBloc {}

void main() {
  late MockModelCatalogBloc bloc;

  setUpAll(() => registerFallbackValue(const ModelsRequested()));

  setUp(() => bloc = MockModelCatalogBloc());

  Future<void> pump(
    WidgetTester tester, {
    required ModelCatalogState state,
    void Function(LeafModel)? onContinue,
  }) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<ModelCatalogBloc>.value(
          value: bloc,
          child: ModelCatalogPage(onContinue: onContinue ?? (_) {}),
        ),
      ),
    );
  }

  final ready = ModelCatalogState(
    status: ModelCatalogStatus.ready,
    models: [coffeeModel, durianModel],
    selectedId: 'coffee_rocole',
  );

  testWidgets('shows the header of the design', (tester) async {
    await pump(tester, state: ready);

    expect(find.text('LeafScan'), findsOneWidget);
    expect(find.text('Choose an AI model'), findsOneWidget);
    expect(
      find.text(
        'Each model recognises a different crop. Check its labels before '
        'scanning.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a card for every model', (tester) async {
    await pump(tester, state: ready);

    expect(find.byType(ModelCard), findsNWidgets(2));
  });

  testWidgets('shows a spinner while it loads', (tester) async {
    await pump(
      tester,
      state: const ModelCatalogState(status: ModelCatalogStatus.loading),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ModelCard), findsNothing);
  });

  testWidgets('names the selected model on the button', (tester) async {
    await pump(tester, state: ready);

    expect(find.text('Use Coffee Leaf model'), findsOneWidget);
  });

  testWidgets('follows the selection on the button', (tester) async {
    await pump(
      tester,
      state: ready.copyWith(selectedId: 'durian'),
    );

    expect(find.text('Use Durian Leaf model'), findsOneWidget);
  });

  testWidgets('a tap on a card sends ModelSelected', (tester) async {
    await pump(tester, state: ready);

    await tester.tap(find.text('Durian Leaf'));

    verify(() => bloc.add(const ModelSelected('durian'))).called(1);
  });

  testWidgets('the button hands the selected model to the caller',
      (tester) async {
    LeafModel? chosen;
    await pump(tester, state: ready, onContinue: (model) => chosen = model);

    await tester.tap(find.text('Use Coffee Leaf model'));

    expect(chosen, coffeeModel);
  });

  testWidgets('disables the button while there is no model', (tester) async {
    await pump(
      tester,
      state: const ModelCatalogState(status: ModelCatalogStatus.ready),
    );

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
    expect(button.label, 'Choose a model');
  });

  testWidgets('shows the failure message when no model loads', (tester) async {
    await pump(
      tester,
      state: const ModelCatalogState(
        status: ModelCatalogStatus.failure,
        message: 'no asset',
      ),
    );

    expect(find.text('no asset'), findsOneWidget);
  });
}
