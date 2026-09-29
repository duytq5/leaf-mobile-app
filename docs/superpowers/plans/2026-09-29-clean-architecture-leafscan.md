# LeafScan Clean Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the app on Clean Architecture with BLoC, and implement the six LeafScan screens.

**Architecture:** Three layers per feature. The domain layer holds entities, repository
interfaces and use cases. It imports no package from Flutter. The data layer holds data
sources, models and repository implementations. The presentation layer holds BLoCs, pages
and widgets. A use case returns `Either<Failure, T>`. `get_it` joins the layers.

**Tech Stack:** Flutter 3.47.5, flutter_bloc 9.1.1, equatable 3.0.0, fpdart 1.2.0,
get_it 9.3.0, bloc_test 10.0.0, mocktail, flutter_onnxruntime 1.8.5, image_picker,
shared_preferences.

**Spec:** `docs/superpowers/specs/2026-09-20-mobile-cv-app-design.md` and the design canvas
"LeafScan — Leaf Disease App" (https://claude.ai/artifact/Mn9SU1VFHvHeEr6baSDv38).

## Global Constraints

- The label list comes from the model manifest. No screen holds a label in its code.
- Every domain file imports no Flutter package. Test this with an import check.
- Every use case returns `Either<Failure, T>` from `fpdart`.
- A BLoC never calls a data source. A BLoC calls a use case only.
- Colors: primary `#1558B0`, dark `#0B3A75`, tint `#EAF1FB`, ground `#F4F7FB`,
  text `#122033`, muted `#4F5F78`, border `#D5E0EE`, divider `#E3EAF3`, white `#FFFFFF`.
- Type: Be Vietnam Pro, with `system-ui` as the fallback.
- A primary button is 56 px high. A screen frame is 390 x 844. A card radius is 14 px.
- Every interactive element is a real `Button`, `InkWell` with `Semantics`, or `TextField`.
- iOS deployment target stays 16.0.
- Run `fvm flutter analyze` and `fvm flutter test` after every task. Both must pass.

## The three decisions this plan makes

1. **The design shows labels that the models do not have.** The coffee card lists rust
   levels 1 to 4. The trained model has 3 classes. The durian card lists 5 labels. The
   dataset has 6 folders. Therefore every screen reads the labels from the manifest. The
   design keeps its layout. The data becomes correct.
2. **The model picker needs a second model.** Task 8 exports the durian checkpoint. The
   picker then shows two real models.
3. **The correction screen is new.** The spec of 2026-09-20 has no such screen. The
   correction gives a label, which is a stronger signal than an uncertainty score. Task 16
   adds it. Stage 1 stores a correction on the device. The upload belongs to stage 3.

## File structure

```
lib/
  core/
    error/failures.dart            Failure types for every layer
    usecase/usecase.dart           UseCase<Type, Params> and NoParams
    theme/app_colors.dart          The design tokens
    theme/app_theme.dart           The ThemeData
    widgets/primary_button.dart    The 56 px button of the design
    widgets/screen_scaffold.dart   The app bar with the back arrow
  features/
    consent/
      domain/entities/consent_record.dart
      domain/repositories/consent_repository.dart
      domain/usecases/get_consent.dart
      domain/usecases/save_consent.dart
      data/datasources/consent_local_data_source.dart
      data/models/consent_record_model.dart
      data/repositories/consent_repository_impl.dart
      presentation/bloc/consent_bloc.dart
      presentation/pages/consent_page.dart
      presentation/pages/terms_page.dart
    models/
      domain/entities/leaf_model.dart
      domain/repositories/model_catalog_repository.dart
      domain/usecases/get_models.dart
      domain/usecases/select_model.dart
      data/datasources/model_catalog_local_data_source.dart
      data/models/model_manifest.dart        moved from lib/src/model
      data/repositories/model_catalog_repository_impl.dart
      presentation/bloc/model_catalog_bloc.dart
      presentation/pages/model_catalog_page.dart
      presentation/widgets/model_card.dart
    scan/
      domain/entities/class_score.dart
      domain/entities/uncertainty.dart       moved from lib/src/model
      domain/entities/scan_result.dart
      domain/entities/label_correction.dart
      domain/repositories/scan_repository.dart
      domain/usecases/classify_image.dart
      domain/usecases/pick_image.dart
      domain/usecases/submit_correction.dart
      data/datasources/image_picker_data_source.dart
      data/datasources/onnx_classifier_data_source.dart
      data/datasources/preprocessor.dart     moved from lib/src/model
      data/repositories/scan_repository_impl.dart
      presentation/bloc/scan_bloc.dart
      presentation/bloc/correction_bloc.dart
      presentation/pages/capture_page.dart
      presentation/pages/result_page.dart
      presentation/pages/report_page.dart
  injection_container.dart
  app.dart
  main.dart
```

---

### Task 1: The dependencies and the core layer

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/error/failures.dart`
- Create: `lib/core/usecase/usecase.dart`
- Test: `test/core/usecase/usecase_test.dart`

**Interfaces:**
- Produces: `abstract class Failure extends Equatable { final String message; }`
  with `CacheFailure`, `ModelFailure`, `ImageFailure`, `PermissionFailure`,
  each `const X(String message)`.
- Produces: `abstract class UseCase<Type, Params> { Future<Either<Failure, Type>> call(Params params); }`
  and `class NoParams extends Equatable`.

- [ ] **Step 1: Add the packages**

```bash
fvm flutter pub add flutter_bloc equatable fpdart get_it
fvm flutter pub add dev:bloc_test
fvm flutter pub remove flutter_riverpod
```

- [ ] **Step 2: Write the failing test**

```dart
// test/core/usecase/usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/core/usecase/usecase.dart';

class _Echo extends UseCase<String, String> {
  @override
  Future<Either<Failure, String>> call(String params) async => Right(params);
}

void main() {
  test('a use case returns Right for a good call', () async {
    final result = await _Echo()('hello');
    expect(result.getRight().toNullable(), 'hello');
  });

  test('two failures with the same message are equal', () {
    expect(const CacheFailure('x'), const CacheFailure('x'));
  });

  test('two failure types with the same message are different', () {
    expect(const CacheFailure('x') == const ModelFailure('x'), isFalse);
  });

  test('NoParams instances are equal', () {
    expect(const NoParams(), const NoParams());
  });
}
```

- [ ] **Step 3: Run it. Expect a compile failure**

Run: `fvm flutter test test/core/usecase/usecase_test.dart`
Expected: FAIL, "Target of URI doesn't exist".

- [ ] **Step 4: Write the two files**

```dart
// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

/// The base of every error that crosses a layer boundary.
abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;
  @override
  List<Object?> get props => [message, runtimeType];
}

class CacheFailure extends Failure { const CacheFailure(super.message); }
class ModelFailure extends Failure { const ModelFailure(super.message); }
class ImageFailure extends Failure { const ImageFailure(super.message); }
class PermissionFailure extends Failure { const PermissionFailure(super.message); }
```

```dart
// lib/core/usecase/usecase.dart
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';

/// One action of the domain layer. It returns a failure or a value.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
```

- [ ] **Step 5: Run the test. Expect PASS. Then commit**

```bash
fvm flutter test test/core/usecase/usecase_test.dart
git add pubspec.yaml pubspec.lock lib/core test/core
git commit -m "add the core layer and the bloc packages"
```

---

### Task 2: The design tokens and the theme

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/widgets/primary_button.dart`
- Create: `lib/core/widgets/screen_scaffold.dart`
- Test: `test/core/theme/app_theme_test.dart`
- Test: `test/core/widgets/primary_button_test.dart`

**Interfaces:**
- Produces: `AppColors.primary/primaryDark/tint/ground/text/muted/border/divider/surface`
  as `static const Color`.
- Produces: `AppTheme.light()` returning `ThemeData`.
- Produces: `PrimaryButton({required String label, required VoidCallback? onPressed, IconData? icon})`
  and `SecondaryButton` with the same signature, both 56 px high.
- Produces: `ScreenScaffold({required String title, VoidCallback? onBack, required Widget body, Widget? bottom})`.

- [ ] **Step 1: Write the failing widget test**

```dart
// test/core/widgets/primary_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_disease_mobile/core/theme/app_colors.dart';
import 'package:leaf_disease_mobile/core/widgets/primary_button.dart';

void main() {
  testWidgets('the primary button is 56 pixels high', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PrimaryButton(label: 'Continue', onPressed: () {})),
    ));

    final size = tester.getSize(find.byType(PrimaryButton));
    expect(size.height, 56);
  });

  testWidgets('the primary button reports a tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PrimaryButton(label: 'Continue', onPressed: () => taps++)),
    ));

    await tester.tap(find.text('Continue'));
    expect(taps, 1);
  });

  testWidgets('a null callback disables the button', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PrimaryButton(label: 'Continue', onPressed: null)),
    ));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('the button uses the design primary colour', (tester) async {
    expect(AppColors.primary, const Color(0xFF1558B0));
  });
}
```

- [ ] **Step 2: Run it. Expect a compile failure**

Run: `fvm flutter test test/core/widgets/primary_button_test.dart`

- [ ] **Step 3: Write the token file and the widgets**

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// The colours of the LeafScan design. Do not write a hex value anywhere else.
abstract final class AppColors {
  static const primary = Color(0xFF1558B0);
  static const primaryDark = Color(0xFF0B3A75);
  static const tint = Color(0xFFEAF1FB);
  static const ground = Color(0xFFF4F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF122033);
  static const textStrong = Color(0xFF33445C);
  static const muted = Color(0xFF4F5F78);
  static const border = Color(0xFFD5E0EE);
  static const divider = Color(0xFFE3EAF3);
  static const dashed = Color(0xFF9FB7D6);
  static const chipGrey = Color(0xFFF1F4F8);
  static const imageGround = Color(0xFFE4EDF8);
}
```

The theme sets `fontFamily: 'BeVietnamPro'` when the font asset exists, and the
`ColorScheme` from `AppColors.primary`. `PrimaryButton` wraps a `FilledButton` in a
`SizedBox(height: 56, width: double.infinity)`. `SecondaryButton` wraps an
`OutlinedButton` the same way. `ScreenScaffold` builds the 64 px bar of the design with a
44 px back target and a 1 px `AppColors.divider` bottom border.

- [ ] **Step 4: Run the test. Expect PASS**

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme lib/core/widgets test/core
git commit -m "add the leafscan design tokens and the shared widgets"
```

---

### Task 3: Move the tested domain code into the new structure

**Files:**
- Create: `lib/features/scan/domain/entities/uncertainty.dart` (from `lib/src/model/uncertainty.dart`)
- Create: `lib/features/scan/domain/entities/class_score.dart` (from `lib/src/model/prediction.dart`)
- Create: `lib/features/models/data/models/model_manifest.dart` (from `lib/src/model/model_manifest.dart`)
- Create: `lib/features/scan/data/datasources/preprocessor.dart` (from `lib/src/model/preprocessor.dart`)
- Move: the four test files to mirror the new paths
- Delete: `lib/src/model/uncertainty.dart`, `prediction.dart`, `model_manifest.dart`, `preprocessor.dart`

**Interfaces:**
- Produces: `softmax(List<double>) -> List<double>`, unchanged.
- Produces: `Uncertainty.fromProbabilities(List<double>)` with `entropy`, `leastConfidence`,
  `margin`, `toJson()`. Now extends `Equatable`.
- Produces: `ClassScore(String label, double probability)`, now extends `Equatable`.
- Produces: `ModelManifest`, `InputSpec`, `ManifestFormatException`, unchanged fields.
- Produces: `Preprocessor(InputSpec spec)` with `run(Uint8List)` and `runOnImage(img.Image)`.

The behaviour does not change. Only the path and the `Equatable` base change. The 43
existing tests must pass after the move with no change to an expectation.

- [ ] **Step 1: Move the files with git mv, then fix every import**

- [ ] **Step 2: Add Equatable to Uncertainty and ClassScore**

- [ ] **Step 3: Run the moved tests. Expect PASS, 43 tests**

Run: `fvm flutter test test/features`

- [ ] **Step 4: Add the domain purity test**

```dart
// test/architecture_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no domain file imports Flutter', () {
    final offenders = <String>[];
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (!entity.path.contains('/domain/')) continue;
      final source = entity.readAsStringSync();
      if (source.contains("package:flutter/")) offenders.add(entity.path);
    }
    expect(offenders, isEmpty, reason: 'the domain layer must not use Flutter');
  });

  test('no bloc imports a data source', () {
    final offenders = <String>[];
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('_bloc.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('data/datasources')) offenders.add(entity.path);
    }
    expect(offenders, isEmpty, reason: 'a bloc uses a use case, never a data source');
  });
}
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "move the tested code into the feature structure"
```

---

### Task 4: Consent domain

**Files:**
- Create: `lib/features/consent/domain/entities/consent_record.dart`
- Create: `lib/features/consent/domain/repositories/consent_repository.dart`
- Create: `lib/features/consent/domain/usecases/get_consent.dart`
- Create: `lib/features/consent/domain/usecases/save_consent.dart`
- Test: `test/features/consent/domain/usecases/get_consent_test.dart`
- Test: `test/features/consent/domain/usecases/save_consent_test.dart`

**Interfaces:**
- Produces: `class ConsentRecord extends Equatable { final bool agreed; final DateTime? agreedAt; const ConsentRecord({required this.agreed, this.agreedAt}); static const none = ConsentRecord(agreed: false); }`
- Produces: `abstract class ConsentRepository { Future<Either<Failure, ConsentRecord>> read(); Future<Either<Failure, Unit>> write(ConsentRecord record); }`
- Produces: `class GetConsent extends UseCase<ConsentRecord, NoParams>`
- Produces: `class SaveConsent extends UseCase<Unit, ConsentRecord>`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/consent/domain/usecases/get_consent_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:leaf_disease_mobile/core/error/failures.dart';
import 'package:leaf_disease_mobile/core/usecase/usecase.dart';
import 'package:leaf_disease_mobile/features/consent/domain/entities/consent_record.dart';
import 'package:leaf_disease_mobile/features/consent/domain/repositories/consent_repository.dart';
import 'package:leaf_disease_mobile/features/consent/domain/usecases/get_consent.dart';

class MockConsentRepository extends Mock implements ConsentRepository {}

void main() {
  late MockConsentRepository repository;
  late GetConsent usecase;

  setUp(() {
    repository = MockConsentRepository();
    usecase = GetConsent(repository);
  });

  test('returns the record of the repository', () async {
    final record = ConsentRecord(agreed: true, agreedAt: DateTime(2026, 9, 29));
    when(() => repository.read()).thenAnswer((_) async => Right(record));

    final result = await usecase(const NoParams());

    expect(result.getRight().toNullable(), record);
    verify(() => repository.read()).called(1);
  });

  test('passes a failure through', () async {
    when(() => repository.read())
        .thenAnswer((_) async => const Left(CacheFailure('no store')));

    final result = await usecase(const NoParams());

    expect(result.isLeft(), isTrue);
  });
}
```

- [ ] **Step 2: Run it. Expect a compile failure**
- [ ] **Step 3: Write the entity, the interface and the two use cases**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the consent domain layer"
```

---

### Task 5: Consent data

**Files:**
- Create: `lib/features/consent/data/datasources/consent_local_data_source.dart`
- Create: `lib/features/consent/data/models/consent_record_model.dart`
- Create: `lib/features/consent/data/repositories/consent_repository_impl.dart`
- Test: `test/features/consent/data/repositories/consent_repository_impl_test.dart`
- Test: `test/features/consent/data/models/consent_record_model_test.dart`

**Interfaces:**
- Consumes: `ConsentRecord`, `ConsentRepository`, `CacheFailure`.
- Produces: `abstract class ConsentLocalDataSource { Future<ConsentRecordModel?> read(); Future<void> write(ConsentRecordModel model); }`
- Produces: `class ConsentLocalDataSourceImpl implements ConsentLocalDataSource` using
  `SharedPreferences` with the keys `consent.agreed` and `consent.agreedAt`.
- Produces: `class ConsentRecordModel extends ConsentRecord` with `fromJson`/`toJson`.
- Produces: `class ConsentRepositoryImpl implements ConsentRepository`. An absent record
  returns `Right(ConsentRecord.none)`. An exception returns `Left(CacheFailure(...))`.

- [ ] **Step 1: Write the failing repository test with a mock data source**

The test asserts: a stored record comes back as `Right`; an absent record gives
`Right(ConsentRecord.none)`; a thrown exception gives `Left(CacheFailure)`.

- [ ] **Step 2: Run it. Expect a compile failure**
- [ ] **Step 3: Write the model, the data source and the implementation**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the consent data layer"
```

---

### Task 6: Consent BLoC

**Files:**
- Create: `lib/features/consent/presentation/bloc/consent_bloc.dart`
- Test: `test/features/consent/presentation/bloc/consent_bloc_test.dart`

**Interfaces:**
- Produces: events `ConsentRequested()`, `ConsentToggled(bool checked)`, `ConsentAccepted()`.
- Produces: `class ConsentState extends Equatable` with
  `ConsentStatus status` (`initial`, `loading`, `ready`, `accepted`, `failure`),
  `bool checked`, `String? message`, and `copyWith`.
- Produces: `class ConsentBloc extends Bloc<ConsentEvent, ConsentState>` taking
  `{required GetConsent getConsent, required SaveConsent saveConsent}`.

Rules the tests pin down:
- `ConsentRequested` with a stored agreement emits `loading` then `accepted`.
- `ConsentRequested` with no agreement emits `loading` then `ready`.
- `ConsentToggled(true)` sets `checked` to true and keeps the status.
- `ConsentAccepted` while `checked` is false emits nothing.
- `ConsentAccepted` while `checked` is true writes the record and emits `accepted`.
- A write failure emits `failure` with the message.

- [ ] **Step 1: Write the failing bloc_test cases (six blocTest blocks)**
- [ ] **Step 2: Run them. Expect a compile failure**
- [ ] **Step 3: Write the BLoC**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the consent bloc"
```

---

### Task 7: Consent and terms screens

**Files:**
- Create: `lib/features/consent/presentation/pages/consent_page.dart`
- Create: `lib/features/consent/presentation/pages/terms_page.dart`
- Test: `test/features/consent/presentation/pages/consent_page_test.dart`

**Interfaces:**
- Consumes: `ConsentBloc`, `AppColors`, `PrimaryButton`.
- Produces: `ConsentPage` and `TermsPage`, both `StatelessWidget`.

The page repeats artboard `0 · Consensus`: a 72 px rounded logo tile, the title
"Before you start", the paragraph, three rows of an icon tile plus a title and a line of
text, the "Read full terms" link, then a bottom block with the checkbox, the primary
button "Agree & continue" and the text button "Close app". The three rows read:

| Title | Text |
|---|---|
| Photos are uploaded | Every image you take or choose is uploaded to our server. |
| Used to train AI | Images and their labels are used to train and improve the models. |
| Your corrections count | When you report a wrong label, your correction is sent too. |

The button is disabled while the checkbox is clear. The test pumps the page with a mock
BLoC and asserts the disabled state, then the enabled state after a tap on the checkbox.

- [ ] **Step 1: Write the failing widget test**
- [ ] **Step 2: Run it. Expect a compile failure**
- [ ] **Step 3: Write the two pages**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the consent and terms screens"
```

---

### Task 8: Export the durian model and write the catalog

**Files:**
- Create: `assets/models/coffee/manifest.json` (moved from `assets/models/manifest.json`)
- Create: `assets/models/durian/manifest.json`
- Create: `assets/models/catalog.json`
- Modify: `pubspec.yaml` asset entries
- Modify: `assets/models/README.md`
- Modify: `tools/export_onnx.py` to accept `--labels-from` a folder
- Test: `test/features/models/data/catalog_asset_test.dart`

**Interfaces:**
- Produces: `assets/models/catalog.json` shaped
  `{"models":[{"id":"coffee_rocole","display_name":"Coffee Leaf","dataset":"RoCoLe","dir":"assets/models/coffee"},{"id":"durian","display_name":"Durian Leaf","dataset":"Vietnamese durian","dir":"assets/models/durian"}]}`.

The durian labels come from the folder names under
`raw_data/durian/train`, sorted: `Leaf_Algal`, `Leaf_Blight`, `Leaf_Colletotrichum`,
`Leaf_Healthy`, `Leaf_Phomopsis`, `Leaf_Rhizoctonia`. Six labels, not the five of the
design.

- [ ] **Step 1: Export the durian checkpoint**

```bash
../active-learning/.venv/bin/python tools/export_onnx.py \
  --checkpoint ../leaf-disease-active-learning-package/checkpoints/durian_fastvit_t8/fold_3_best.pt \
  --output assets/models/durian/model.onnx
```

- [ ] **Step 2: Verify both models on real images**

```bash
../active-learning/.venv/bin/python tools/verify_onnx.py \
  --model assets/models/durian/model.onnx \
  --manifest assets/models/durian/manifest.json \
  --data ../leaf-disease-active-learning-package/raw_data/durian/train --per-class 4
```

Expected: an accuracy above 70%. A lower number means a wrong label order.

- [ ] **Step 3: Write catalog.json and the asset test**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the durian model and the model catalog"
```

---

### Task 9: Models domain and data

**Files:**
- Create: `lib/features/models/domain/entities/leaf_model.dart`
- Create: `lib/features/models/domain/repositories/model_catalog_repository.dart`
- Create: `lib/features/models/domain/usecases/get_models.dart`
- Create: `lib/features/models/domain/usecases/select_model.dart`
- Create: `lib/features/models/data/datasources/model_catalog_local_data_source.dart`
- Create: `lib/features/models/data/repositories/model_catalog_repository_impl.dart`
- Test: one file per unit under `test/features/models/`

**Interfaces:**
- Produces:

```dart
class LeafModel extends Equatable {
  const LeafModel({
    required this.id,
    required this.displayName,
    required this.dataset,
    required this.version,
    required this.labels,
    required this.modelAsset,
    required this.manifest,
  });
  final String id;
  final String displayName;
  final String dataset;
  final String version;
  final List<String> labels;
  final String modelAsset;
  final ModelManifest manifest;
  int get labelCount => labels.length;
}
```

- Produces: `abstract class ModelCatalogRepository { Future<Either<Failure, List<LeafModel>>> getModels(); Future<Either<Failure, LeafModel>> getSelected(); Future<Either<Failure, Unit>> select(String id); }`
- Produces: `GetModels extends UseCase<List<LeafModel>, NoParams>`,
  `SelectModel extends UseCase<Unit, String>`.
- The data source reads `assets/models/catalog.json`, then each `manifest.json`, and
  builds a `LeafModel`. The selected id lives in `SharedPreferences` under
  `models.selected`. With no stored id the first model of the catalog is selected.

- [ ] **Step 1: Write the failing tests for the repository and the use cases**
- [ ] **Step 2: Run them. Expect a compile failure**
- [ ] **Step 3: Write the files**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the model catalog domain and data layers"
```

---

### Task 10: Model catalog BLoC and screen

**Files:**
- Create: `lib/features/models/presentation/bloc/model_catalog_bloc.dart`
- Create: `lib/features/models/presentation/pages/model_catalog_page.dart`
- Create: `lib/features/models/presentation/widgets/model_card.dart`
- Test: `test/features/models/presentation/bloc/model_catalog_bloc_test.dart`
- Test: `test/features/models/presentation/widgets/model_card_test.dart`

**Interfaces:**
- Produces: events `ModelsRequested()`, `ModelSelected(String id)`.
- Produces: `ModelCatalogState` with `status`, `List<LeafModel> models`, `String? selectedId`, `String? message`.
- Produces: `ModelCard({required LeafModel model, required bool selected, required VoidCallback onTap})`.

The screen repeats artboard `1 · Choose model`: a primary header block with the wordmark,
the title "Choose an AI model" and the paragraph, then a scrolling list of cards on the
`ground` colour, then a bottom bar with the primary button. The card shows the display
name, then `<dataset> · <version> · <n> labels`, then one chip for each label **from the
manifest**. The selected card has a 2 px primary border and a filled check circle. The
button label reads `Use <display name> model`.

- [ ] **Step 1: Write the failing bloc and widget tests**

The widget test asserts that a model with 3 labels renders exactly 3 chips, and that the
subtitle reads "3 labels". This is the test that prevents the label error of the design.

- [ ] **Step 2: Run them. Expect a compile failure**
- [ ] **Step 3: Write the BLoC, the card and the page**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the model catalog bloc and screen"
```

---

### Task 11: Scan domain

**Files:**
- Create: `lib/features/scan/domain/entities/scan_result.dart`
- Create: `lib/features/scan/domain/entities/label_correction.dart`
- Create: `lib/features/scan/domain/repositories/scan_repository.dart`
- Create: `lib/features/scan/domain/usecases/classify_image.dart`
- Create: `lib/features/scan/domain/usecases/pick_image.dart`
- Create: `lib/features/scan/domain/usecases/submit_correction.dart`
- Test: one file per use case

**Interfaces:**
- Produces:

```dart
class ScanResult extends Equatable {
  const ScanResult({
    required this.imageBytes,
    required this.scores,
    required this.uncertainty,
    required this.latency,
    required this.modelId,
    required this.modelVersion,
  });
  final Uint8List imageBytes;
  final List<ClassScore> scores;   // highest probability first
  final Uncertainty uncertainty;
  final Duration latency;
  final String modelId;
  final String modelVersion;
  ClassScore get top => scores.first;
}
```

- Produces: `class LabelCorrection extends Equatable` with `modelId`, `predictedLabel`,
  `correctedLabel`, `submittedAt`.
- Produces: `abstract class ScanRepository { Future<Either<Failure, Uint8List>> pickImage(ImageSourceKind source); Future<Either<Failure, ScanResult>> classify({required Uint8List bytes, required LeafModel model}); Future<Either<Failure, Unit>> saveCorrection(LabelCorrection correction); }`
- Produces: `enum ImageSourceKind { camera, gallery }` in the domain layer, so the domain
  does not import `image_picker`.
- Produces: `ClassifyImage extends UseCase<ScanResult, ClassifyParams>` where
  `ClassifyParams({required Uint8List bytes, required LeafModel model})`.
- Produces: `PickImage extends UseCase<Uint8List, ImageSourceKind>`.
- Produces: `SubmitCorrection extends UseCase<Unit, LabelCorrection>`.

- [ ] **Step 1: Write the failing tests for the three use cases**
- [ ] **Step 2: Run them. Expect a compile failure**
- [ ] **Step 3: Write the entities, the interface and the use cases**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the scan domain layer"
```

---

### Task 12: Scan data

**Files:**
- Create: `lib/features/scan/data/datasources/image_picker_data_source.dart`
- Create: `lib/features/scan/data/datasources/onnx_classifier_data_source.dart`
- Create: `lib/features/scan/data/repositories/scan_repository_impl.dart`
- Delete: `lib/src/model/classifier.dart`, `lib/src/model/model_loader.dart`
- Test: `test/features/scan/data/repositories/scan_repository_impl_test.dart`

**Interfaces:**
- Produces: `abstract class OnnxClassifierDataSource { Future<List<double>> run({required Uint8List bytes, required LeafModel model}); Future<void> close(); }`.
  The implementation keeps one `OrtSession` per model id in a `Map`, so a second scan with
  the same model reuses the session.
- Produces: `abstract class ImagePickerDataSource { Future<Uint8List?> pick(ImageSourceKind source); }`.
- Produces: `class ScanRepositoryImpl implements ScanRepository`. It converts the logits
  into a `ScanResult` with `softmax`, `Uncertainty.fromProbabilities` and the labels of the
  model. A cancelled picker returns `Left(ImageFailure('no image'))`.

The repository test uses a fake data source that returns fixed logits. It asserts that the
scores come back sorted, that the label pairing is correct, and that a logit count that
differs from the label count gives `Left(ModelFailure)`.

- [ ] **Step 1: Write the failing repository test**
- [ ] **Step 2: Run it. Expect a compile failure**
- [ ] **Step 3: Write the data sources and the implementation**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the scan data layer"
```

---

### Task 13: Scan BLoC

**Files:**
- Create: `lib/features/scan/presentation/bloc/scan_bloc.dart`
- Test: `test/features/scan/presentation/bloc/scan_bloc_test.dart`

**Interfaces:**
- Produces: events `ScanImageRequested(ImageSourceKind source, LeafModel model)`,
  `ScanCleared()`.
- Produces: `ScanState` with `ScanStatus status` (`idle`, `picking`, `running`, `done`,
  `failure`), `ScanResult? result`, `String? message`.
- Produces: `ScanBloc({required PickImage pickImage, required ClassifyImage classifyImage})`.

Rules the tests pin down:
- A good scan emits `picking`, `running`, `done`.
- A cancelled picker emits `picking` then `idle`, with no message.
- A classify failure emits `picking`, `running`, `failure` with the message.
- `ScanCleared` returns the state to `idle` and drops the result.

- [ ] **Step 1: Write the failing bloc tests**
- [ ] **Step 2: Run them. Expect a compile failure**
- [ ] **Step 3: Write the BLoC**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the scan bloc"
```

---

### Task 14: Capture screen

**Files:**
- Create: `lib/features/scan/presentation/pages/capture_page.dart`
- Test: `test/features/scan/presentation/pages/capture_page_test.dart`

The page repeats artboard `2 · Add photo`: the `ScreenScaffold` with the title "New scan"
and a back arrow, a rounded chip showing `<model name> · <version>`, a dashed drop area
with a 72 px circular icon, the title "Add a photo of one leaf" and the line "Use daylight
and a plain background. Let the leaf fill most of the frame.", then the primary button
"Take photo" and the secondary button "Choose from library".

While the state is `running` the two buttons are disabled and a progress indicator shows.
When the state becomes `done` the page pushes the result page.

- [ ] **Step 1: Write the failing widget test**
- [ ] **Step 2: Run it. Expect a compile failure**
- [ ] **Step 3: Write the page**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the capture screen"
```

---

### Task 15: Result screen

**Files:**
- Create: `lib/features/scan/presentation/pages/result_page.dart`
- Test: `test/features/scan/presentation/pages/result_page_test.dart`

The page repeats artboard `3 · Result`: the bar with the title "Result", the photo in a
340 px rounded box, then a card with "Predicted label", the label at 26 px bold in
`primaryDark`, a progress bar plus the percentage, and the line `<model name> · <version>`.
The bottom holds the primary button "Continue" and the secondary button "Report wrong
label".

The design shows one label only. The thesis needs every number. Therefore the card gets a
`TextButton` "Show all scores" that expands a list of every class with its percentage,
plus the latency, the entropy and the margin. The list is collapsed by default, so the
screen matches the design at rest.

- [ ] **Step 1: Write the failing widget test**

The test asserts: the top label shows; the percentage matches the top probability; the
extra scores are absent until the button is tapped; after the tap every label appears.

- [ ] **Step 2: Run it. Expect a compile failure**
- [ ] **Step 3: Write the page**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the result screen"
```

---

### Task 16: Correction BLoC and report screen

**Files:**
- Create: `lib/features/scan/presentation/bloc/correction_bloc.dart`
- Create: `lib/features/scan/presentation/pages/report_page.dart`
- Create: `lib/features/scan/data/datasources/correction_local_data_source.dart`
- Test: `test/features/scan/presentation/bloc/correction_bloc_test.dart`
- Test: `test/features/scan/presentation/pages/report_page_test.dart`

**Interfaces:**
- Produces: events `CorrectionLabelChosen(String label)`, `CorrectionSubmitted()`.
- Produces: `CorrectionState` with `status`, `String? chosen`, `String? message`.
- Produces: `CorrectionBloc({required SubmitCorrection submitCorrection, required ScanResult result, required LeafModel model})`.
- The local data source appends a JSON line to a file in the documents directory. Stage 3
  uploads that file.

The page repeats artboard `4 · Report wrong label`: the bar, a row with a 64 px thumbnail
and the predicted label with a line through it, the legend "What is the correct label?",
then a radio row for **every label of the model** plus a final row "Not sure / other", then
the primary button "Submit correction".

The radio list comes from `model.labels`. The test asserts that a model with 3 labels
renders 4 rows, three labels plus "Not sure / other".

- [ ] **Step 1: Write the failing bloc and widget tests**
- [ ] **Step 2: Run them. Expect a compile failure**
- [ ] **Step 3: Write the data source, the BLoC and the page**
- [ ] **Step 4: Run the tests. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "add the label correction bloc and screen"
```

---

### Task 17: Dependency injection, routing and the app shell

**Files:**
- Create: `lib/injection_container.dart`
- Modify: `lib/app.dart`
- Modify: `lib/main.dart`
- Delete: `lib/src/app.dart`, `lib/src/ui/home_screen.dart`, the empty `lib/src`
- Modify: `test/app_test.dart`

**Interfaces:**
- Produces: `Future<void> initDependencies()` registering, in order: the external
  `SharedPreferences`, then each data source as a lazy singleton, then each repository,
  then each use case, then each BLoC as a factory.
- Produces: `class LeafScanApp extends StatelessWidget` with routes
  `/` (consent gate), `/models`, `/capture`, `/result`, `/report`, `/terms`.
- The gate reads the consent state. An agreed record opens `/models`. A clear record opens
  the consent page.

- [ ] **Step 1: Write the failing app test**

The test pumps `LeafScanApp` with a registered fake and asserts that the consent page shows
first, then that an accepted consent shows the model catalog page.

- [ ] **Step 2: Run it. Expect a compile failure**
- [ ] **Step 3: Write the container, the routes and the shell. Delete the old files**
- [ ] **Step 4: Run the whole suite. Expect PASS**
- [ ] **Step 5: Commit**

```bash
git commit -m "wire the features with get_it and the router"
```

---

### Task 18: Verification on the simulator

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-09-20-mobile-cv-app-design.md` (record the new structure)

- [ ] **Step 1: Run the whole suite and the analyzer**

```bash
fvm flutter analyze
fvm flutter test
```

Both must report no issue.

- [ ] **Step 2: Build and run on the iOS simulator**

```bash
fvm flutter build ios --simulator --debug
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted dev.leafscout.leafDiseaseMobile
```

- [ ] **Step 3: Walk the flow and capture a screenshot of each screen**

Consent, models, capture, result, report. Save each to the scratchpad and look at it.
Compare each against its artboard.

- [ ] **Step 4: Write the state table in the README**

- [ ] **Step 5: Commit**

```bash
git commit -m "record the clean architecture structure in the readme"
```
