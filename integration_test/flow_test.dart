import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:leaf_disease_mobile/app.dart';
import 'package:leaf_disease_mobile/features/consent/presentation/pages/consent_page.dart';
import 'package:leaf_disease_mobile/features/models/presentation/pages/model_catalog_page.dart';
import 'package:leaf_disease_mobile/features/models/presentation/widgets/model_card.dart';
import 'package:leaf_disease_mobile/features/scan/presentation/pages/capture_page.dart';
import 'package:leaf_disease_mobile/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Walks the real app on a device.
///
/// This test runs the real ONNX models and the real device store. It proves
/// that the models load on the platform, which a widget test cannot show.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Every run starts at the agreement screen.
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
  });

  testWidgets('the app walks from the agreement to the capture screen',
      (tester) async {
    await tester.pumpWidget(const LeafScanApp());
    await tester.pumpAndSettle();

    // 0 · Consensus
    expect(find.byType(ConsentPage), findsOneWidget);
    expect(find.text('Before you start'), findsOneWidget);
    await binding.takeScreenshot('01-consent');

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agree & continue'));
    await tester.pumpAndSettle();

    // 1 · Choose model
    expect(find.byType(ModelCatalogPage), findsOneWidget);
    expect(find.text('Choose an AI model'), findsOneWidget);
    // Both models load from the assets, with the labels of their manifests.
    expect(find.byType(ModelCard), findsNWidgets(2));
    expect(find.text('RoCoLe · fold-1-best · 3 labels'), findsOneWidget);
    expect(
      find.text('Vietnamese durian · fold-3-best · 6 labels'),
      findsOneWidget,
    );
    await binding.takeScreenshot('02-models');

    await tester.tap(find.text('Use Coffee Leaf model'));
    await tester.pumpAndSettle();

    // 2 · Add photo
    expect(find.byType(CapturePage), findsOneWidget);
    expect(find.text('Add a photo of one leaf'), findsOneWidget);
    expect(find.text('Coffee Leaf · fold-1-best'), findsOneWidget);
    await binding.takeScreenshot('03-capture');
  });

  testWidgets('the durian model is selectable and drives the button',
      (tester) async {
    await tester.pumpWidget(const LeafScanApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agree & continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Durian Leaf'));
    await tester.pumpAndSettle();

    expect(find.text('Use Durian Leaf model'), findsOneWidget);

    await tester.tap(find.text('Use Durian Leaf model'));
    await tester.pumpAndSettle();

    expect(find.text('Durian Leaf · fold-3-best'), findsOneWidget);
  });

  testWidgets('the agreement is stored, so a restart skips it', (tester) async {
    await tester.pumpWidget(const LeafScanApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agree & continue'));
    await tester.pumpAndSettle();

    // Start the app again with the same store.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const LeafScanApp());
    await tester.pumpAndSettle();

    expect(find.byType(ConsentPage), findsNothing);
    expect(find.byType(ModelCatalogPage), findsOneWidget);
  });
}
