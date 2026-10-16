import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:leaf_disease_mobile/app.dart';
import 'package:leaf_disease_mobile/features/auth/data/datasources/token_store.dart';
import 'package:leaf_disease_mobile/features/auth/presentation/pages/sign_in_page.dart';
import 'package:leaf_disease_mobile/features/consent/presentation/pages/consent_page.dart';
import 'package:leaf_disease_mobile/features/models/presentation/pages/model_catalog_page.dart';
import 'package:leaf_disease_mobile/features/models/presentation/widgets/model_card.dart';
import 'package:leaf_disease_mobile/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Walks the real app on a device.
///
/// This test runs the real device store and the real Edge API, so the model
/// list shows what the platform has released.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Every run starts at the agreement screen.
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initDependencies();
    // The models open only for a signed-in user, and a test cannot sign in to
    // Google, so every run starts with a stored session.
    await sl<TokenStore>().write(
      StoredSession(
        accessToken: 'test',
        refreshToken: 'test',
        expiresAt: DateTime.utc(2100),
      ),
    );
  });

  testWidgets('the app walks from the agreement to the model list',
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

    // 1 · Choose model. The app ships no model, so the list holds the
    // platform's releases, or says there is none yet.
    expect(find.byType(ModelCatalogPage), findsOneWidget);
    expect(find.text('Choose an AI model'), findsOneWidget);
    expect(
      find.byType(ModelCard).evaluate().isNotEmpty ||
          find.text('No models yet').evaluate().isNotEmpty,
      isTrue,
    );
    await binding.takeScreenshot('02-models');
  });

  testWidgets('a signed-out user meets the sign-in screen, not the models',
      (tester) async {
    await sl<TokenStore>().clear();
    await tester.pumpWidget(const LeafScanApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agree & continue'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.byType(ModelCatalogPage), findsNothing);
    await binding.takeScreenshot('00-sign-in');
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
