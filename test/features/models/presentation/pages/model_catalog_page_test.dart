import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/core/widgets/primary_button.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/catalog_entry.dart';
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

  final coffee = CatalogEntry(
    id: 'coffee_rocole',
    displayName: 'Coffee Leaf',
    cropName: 'RoCoLe',
    installed: coffeeModel,
  );
  final durian = CatalogEntry(
    id: 'durian',
    displayName: 'Durian Leaf',
    cropName: 'Vietnamese durian',
    installed: durianModel,
  );
  const missing = CatalogEntry(
    id: 'rocole',
    displayName: 'Lá cà phê (RoCoLe)',
    cropName: 'Cà phê',
    releasedVersion: 3,
  );

  final ready = ModelCatalogState(
    status: ModelCatalogStatus.ready,
    entries: [coffee, durian],
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
      state: ready.copyWith(selectedId: () => 'durian'),
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
        failure: ModelFailure(
          'no asset',
          code: FailureCode.catalogUnreadable,
        ),
      ),
    );

    // The screen names the problem, not the technical message.
    expect(find.text('no asset'), findsNothing);
    expect(
      find.text('The app cannot read the models. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('says when the platform has released no model yet',
      (tester) async {
    await pump(
      tester,
      state: const ModelCatalogState(status: ModelCatalogStatus.ready),
    );

    expect(find.text('No models yet'), findsOneWidget);
    expect(
      find.text(
        'No crop has a released model yet. Check again later.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the empty list can be loaded again', (tester) async {
    await pump(
      tester,
      state: const ModelCatalogState(status: ModelCatalogStatus.ready),
    );

    await tester.tap(find.text('Try again'));

    verify(() => bloc.add(const ModelsRequested())).called(1);
  });

  testWidgets('a failure with no model can be loaded again', (tester) async {
    await pump(
      tester,
      state: const ModelCatalogState(
        status: ModelCatalogStatus.failure,
        failure: NetworkFailure(
          'offline',
          code: FailureCode.catalogOffline,
        ),
      ),
    );

    expect(
      find.text('No connection. Connect to the internet to download a model.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));

    verify(() => bloc.add(const ModelsRequested())).called(1);
  });

  testWidgets('a model that is not downloaded keeps the button disabled',
      (tester) async {
    await pump(
      tester,
      state: const ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [missing],
      ),
    );

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
    expect(button.label, 'Download a model to start');
  });

  testWidgets('the download button asks the bloc to download', (tester) async {
    await pump(
      tester,
      state: const ModelCatalogState(
        status: ModelCatalogStatus.ready,
        entries: [missing],
      ),
    );

    await tester.tap(find.text('Download'));

    verify(() => bloc.add(const ModelDownloadRequested('rocole'))).called(1);
  });

  testWidgets('a delete asks first, then asks the bloc', (tester) async {
    await pump(tester, state: ready);

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete Coffee Leaf?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
    await tester.pumpAndSettle();

    verify(() => bloc.add(const ModelDeleteRequested('coffee_rocole')))
        .called(1);
  });

  testWidgets('a cancelled delete keeps the model', (tester) async {
    await pump(tester, state: ready);

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => bloc.add(const ModelDeleteRequested('coffee_rocole')));
  });

  testWidgets('a download error shows in a snackbar', (tester) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    whenListen(
      bloc,
      Stream.value(ready.copyWith(
          failure: NetworkFailure(
            'expired',
            code: FailureCode.downloadFailed,
          ),
        ),),
      initialState: ready,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<ModelCatalogBloc>.value(
          value: bloc,
          child: ModelCatalogPage(onContinue: (_) {}),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('The download failed. Please try again.'),
      findsOneWidget,
    );
  });
}
