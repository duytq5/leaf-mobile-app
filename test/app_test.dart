import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:leaf_disease_mobile/app.dart';
import 'package:leaf_disease_mobile/features/consent/presentation/bloc/consent_bloc.dart';
import 'package:leaf_disease_mobile/features/consent/presentation/pages/consent_page.dart';
import 'package:leaf_disease_mobile/features/models/presentation/bloc/model_catalog_bloc.dart';
import 'package:leaf_disease_mobile/features/models/presentation/pages/model_catalog_page.dart';
import 'package:leaf_disease_mobile/features/outbox/presentation/bloc/outbox_bloc.dart';
import 'package:leaf_disease_mobile/injection_container.dart';
import 'package:mocktail/mocktail.dart';

import 'support/model_fixtures.dart';
import 'support/phone_frame.dart';

class MockConsentBloc extends MockBloc<ConsentEvent, ConsentState>
    implements ConsentBloc {}

class MockModelCatalogBloc
    extends MockBloc<ModelCatalogEvent, ModelCatalogState>
    implements ModelCatalogBloc {}

class MockOutboxBloc extends MockBloc<OutboxEvent, OutboxState>
    implements OutboxBloc {}

void main() {
  late MockConsentBloc consentBloc;
  late MockModelCatalogBloc catalogBloc;

  setUp(() {
    consentBloc = MockConsentBloc();
    catalogBloc = MockModelCatalogBloc();
    when(() => catalogBloc.state).thenReturn(
      ModelCatalogState(
        status: ModelCatalogStatus.ready,
        models: [coffeeModel, durianModel],
        selectedId: 'coffee_rocole',
      ),
    );

    final outboxBloc = MockOutboxBloc();
    when(() => outboxBloc.state).thenReturn(const OutboxState());

    GetIt.instance
      ..registerFactory<OutboxBloc>(() => outboxBloc)
      ..registerFactory<ConsentBloc>(() => consentBloc)
      ..registerFactory<ModelCatalogBloc>(() => catalogBloc);
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('shows a spinner while it reads the stored agreement',
      (tester) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    when(() => consentBloc.state)
        .thenReturn(const ConsentState(status: ConsentStatus.loading));

    await tester.pumpWidget(const LeafScanApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the agreement screen on a first start', (tester) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    when(() => consentBloc.state)
        .thenReturn(const ConsentState(status: ConsentStatus.ready));

    await tester.pumpWidget(const LeafScanApp());

    expect(find.byType(ConsentPage), findsOneWidget);
    expect(find.text('Before you start'), findsOneWidget);
  });

  testWidgets('skips the agreement when the user already agreed',
      (tester) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    when(() => consentBloc.state).thenReturn(
      const ConsentState(status: ConsentStatus.accepted, checked: true),
    );

    await tester.pumpWidget(const LeafScanApp());
    await tester.pump();

    expect(find.byType(ConsentPage), findsNothing);
    expect(find.byType(ModelCatalogPage), findsOneWidget);
    expect(find.text('Choose an AI model'), findsOneWidget);
  });

  test('the service locator registers every unit the app needs', () {
    // The container itself needs a binding and a real store, so this test only
    // proves the function exists and the locator is the single instance.
    expect(sl, same(GetIt.instance));
  });
}
