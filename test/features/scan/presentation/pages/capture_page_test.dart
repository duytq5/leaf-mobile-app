import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/core/widgets/primary_button.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/image_source_kind.dart';
import 'package:leaf_disease_mobile/features/scan/domain/entities/scan_result.dart';
import 'package:leaf_disease_mobile/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:leaf_disease_mobile/features/scan/presentation/pages/capture_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/model_fixtures.dart';
import '../../../../support/phone_frame.dart';
import '../../../../support/scan_fixtures.dart';

class MockScanBloc extends MockBloc<ScanEvent, ScanState>
    implements ScanBloc {}

void main() {
  late MockScanBloc bloc;

  setUpAll(() => registerFallbackValue(const ScanCleared()));

  setUp(() => bloc = MockScanBloc());

  Future<void> pump(
    WidgetTester tester, {
    required ScanState state,
    void Function(ScanResult)? onResult,
  }) async {
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<ScanBloc>.value(
          value: bloc,
          child: CapturePage(
            model: coffeeModel,
            onBack: () {},
            onResult: onResult ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows the guidance of the design', (tester) async {
    await pump(tester, state: const ScanState());

    expect(find.text('New scan'), findsOneWidget);
    expect(find.text('Add a photo of one leaf'), findsOneWidget);
    expect(
      find.text(
        'Use daylight and a plain background. Let the leaf fill most of the '
        'frame.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('names the selected model and its version', (tester) async {
    await pump(tester, state: const ScanState());

    expect(find.text('Coffee Leaf · fold-1-best'), findsOneWidget);
  });

  testWidgets('shows both photo actions', (tester) async {
    await pump(tester, state: const ScanState());

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from library'), findsOneWidget);
  });

  testWidgets('the camera button sends a camera scan', (tester) async {
    await pump(tester, state: const ScanState());

    await tester.tap(find.text('Take photo'));

    verify(
      () => bloc.add(
        ScanImageRequested(source: ImageSourceKind.camera, model: coffeeModel),
      ),
    ).called(1);
  });

  testWidgets('the library button sends a gallery scan', (tester) async {
    await pump(tester, state: const ScanState());

    await tester.tap(find.text('Choose from library'));

    verify(
      () => bloc.add(
        ScanImageRequested(source: ImageSourceKind.gallery, model: coffeeModel),
      ),
    ).called(1);
  });

  testWidgets('disables both buttons while the model runs', (tester) async {
    await pump(tester, state: const ScanState(status: ScanStatus.running));

    final primary = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    final secondary =
        tester.widget<SecondaryButton>(find.byType(SecondaryButton));
    expect(primary.onPressed, isNull);
    expect(secondary.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('hands the result to the caller when the scan finishes',
      (tester) async {
    ScanResult? delivered;
    final result = coffeeScan();
    usePhoneFrame(tester);
    addTearDown(() => resetPhoneFrame(tester));
    whenListen(
      bloc,
      Stream.fromIterable([ScanState(status: ScanStatus.done, result: result)]),
      initialState: const ScanState(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<ScanBloc>.value(
          value: bloc,
          child: CapturePage(
            model: coffeeModel,
            onBack: () {},
            onResult: (value) => delivered = value,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(delivered, result);
  });
}
