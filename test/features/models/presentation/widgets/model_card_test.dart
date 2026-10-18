import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_theme.dart';
import 'package:leaf_disease_mobile/features/models/domain/entities/catalog_entry.dart';
import 'package:leaf_disease_mobile/features/models/presentation/widgets/model_card.dart';
import 'package:leaf_disease_mobile/l10n/generated/app_localizations.dart';

import '../../../../support/model_fixtures.dart';

final _coffee = CatalogEntry(
  id: 'coffee_rocole',
  displayName: 'Coffee Leaf',
  cropName: 'RoCoLe',
  installed: coffeeModel,
);

final _durian = CatalogEntry(
  id: 'durian',
  displayName: 'Durian Leaf',
  cropName: 'Vietnamese durian',
  installed: durianModel,
);

const _missing = CatalogEntry(
  id: 'rocole',
  displayName: 'Lá cà phê (RoCoLe)',
  cropName: 'Cà phê',
  releasedVersion: 3,
);

final _outdated = CatalogEntry(
  id: 'rocole',
  displayName: 'Lá cà phê (RoCoLe)',
  cropName: 'Cà phê',
  releasedVersion: 4,
  installed: releasedModel,
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    CatalogEntry? entry,
    bool selected = false,
    bool downloading = false,
    Locale locale = const Locale('en'),
    double? progress,
    VoidCallback? onTap,
    VoidCallback? onDownload,
    VoidCallback? onDelete,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ModelCard(
              entry: entry ?? _coffee,
              selected: selected,
              downloading: downloading,
              progress: progress,
              onTap: onTap ?? () {},
              onDownload: onDownload ?? () {},
              onDelete: onDelete ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the name and the subtitle from the manifest',
      (tester) async {
    await pump(tester, selected: true);

    expect(find.text('Coffee Leaf'), findsOneWidget);
    expect(find.text('RoCoLe · fold-1-best · 3 labels'), findsOneWidget);
  });

  testWidgets('a released model names its version with a v', (tester) async {
    await pump(tester, entry: _outdated);

    expect(find.text('Cà phê · v3 · 2 labels'), findsOneWidget);
  });

  testWidgets('a Vietnamese phone reads the card in Vietnamese', (
    tester,
  ) async {
    await pump(tester, entry: _outdated, locale: const Locale('vi'));

    expect(find.text('Cà phê · v3 · 2 nhãn'), findsOneWidget);
    expect(find.text('Cập nhật lên v4'), findsOneWidget);
    expect(find.text('Xoá'), findsOneWidget);
  });

  testWidgets('a model that is not on the phone says so in Vietnamese', (
    tester,
  ) async {
    await pump(tester, entry: _missing, locale: const Locale('vi'));

    expect(find.text('Cà phê · v3 · Chưa tải'), findsOneWidget);
    expect(find.text('Tải về'), findsOneWidget);
  });

  testWidgets('shows one chip per label of the model', (tester) async {
    await pump(tester, selected: true);

    expect(find.text('coffee___healthy'), findsOneWidget);
    expect(find.text('coffee___red_spider_mite'), findsOneWidget);
    expect(find.text('coffee___rust'), findsOneWidget);
  });

  testWidgets('a released model shows the display name of each class',
      (tester) async {
    await pump(
      tester,
      entry: CatalogEntry(
        id: 'rocole',
        displayName: 'Lá cà phê (RoCoLe)',
        cropName: 'Cà phê',
        releasedVersion: 3,
        installed: releasedModel,
      ),
    );

    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('Rust'), findsOneWidget);
    expect(find.text('healthy'), findsNothing);
  });

  testWidgets('shows six chips for the durian model', (tester) async {
    await pump(tester, entry: _durian);

    for (final label in durianModel.labels) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('shows a check mark only when selected', (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.check), findsNothing);

    await pump(tester, selected: true);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('reports a tap', (tester) async {
    var taps = 0;
    await pump(tester, onTap: () => taps++);

    await tester.tap(find.text('Coffee Leaf'));

    expect(taps, 1);
  });

  group('a model that is not on the phone', () {
    testWidgets('names its crop and release, and offers a download',
        (tester) async {
      var downloads = 0;
      await pump(tester, entry: _missing, onDownload: () => downloads++);

      expect(find.text('Cà phê · v3 · Not downloaded'), findsOneWidget);
      await tester.tap(find.text('Download'));

      expect(downloads, 1);
    });

    testWidgets('offers no delete', (tester) async {
      await pump(tester, entry: _missing);

      expect(find.text('Delete'), findsNothing);
    });
  });

  group('a download in progress', () {
    testWidgets('shows the share received', (tester) async {
      await pump(tester, entry: _missing, downloading: true, progress: 0.42);

      expect(find.text('Downloading 42%'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.42);
      expect(find.text('Download'), findsNothing);
    });

    testWidgets('without a size shows a moving bar', (tester) async {
      await pump(tester, entry: _missing, downloading: true);

      expect(find.text('Downloading…'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, isNull);
    });
  });

  testWidgets('a downloaded model offers a delete', (tester) async {
    var deletes = 0;
    await pump(tester, onDelete: () => deletes++);

    expect(find.text('Download'), findsNothing);
    await tester.tap(find.text('Delete'));

    expect(deletes, 1);
  });

  testWidgets('an older model offers the update and a delete', (tester) async {
    var downloads = 0;
    await pump(tester, entry: _outdated, onDownload: () => downloads++);

    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Update to v4'));

    expect(downloads, 1);
  });
}
