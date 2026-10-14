# LeafScan

The app runs the thesis leaf disease classifier on a phone. The user selects a model,
takes a photo, and reads the predicted class. The user can also correct a wrong label.
A correction is a label from a person, which the next active learning round can use.

The design canvas is "LeafScan — Leaf Disease App". The stage 1 specification is
`docs/superpowers/specs/2026-09-20-mobile-cv-app-design.md`. The implementation plan is
`docs/superpowers/plans/2026-09-29-clean-architecture-leafscan.md`.

## Stack

| Layer | Choice | Reason |
|---|---|---|
| App framework | Flutter 3.47.5 (Dart) | One codebase for Android and iOS. |
| SDK manager | fvm | The version is pinned in `.fvmrc`. |
| Architecture | Clean Architecture | Three layers for each feature. |
| State | flutter_bloc | One bloc for each screen. The tests read the state. |
| Errors | fpdart `Either` | A use case returns a failure or a value. It never throws. |
| Injection | get_it | One container joins the layers. |
| Inference | ONNX Runtime | The export from PyTorch needs one step. |
| Model | FastViT-T8 | The thesis benchmark selected it. |

## Architecture

```
lib/
  core/            failures, the use case base, the design tokens, shared widgets
  features/
    consent/       the upload agreement
    models/        the model catalog and the picker
    scan/          the capture, the result and the correction
  injection_container.dart
  app.dart         the routes
  main.dart
```

Each feature holds three layers.

| Layer | Holds | Rule |
|---|---|---|
| `domain` | entities, repository interfaces, use cases | It imports no Flutter package and no data package. |
| `data` | data sources, repository implementations | It implements a domain interface. |
| `presentation` | blocs, pages, widgets | A bloc calls a use case, never a data source. |

`test/architecture_test.dart` reads every file and fails when a rule breaks. A screen that
holds its own colour also fails, because a colour belongs in `AppColors`.

## The screens

| Artboard | Page | State |
|---|---|---|
| 0 · Consensus | `consent/presentation/pages/consent_page.dart` | Done. |
| 0b · Full terms | `consent/presentation/pages/terms_page.dart` | Done. |
| 1 · Choose model | `models/presentation/pages/model_catalog_page.dart` | Done. |
| 2 · Add photo | `scan/presentation/pages/capture_page.dart` | Done. |
| 3 · Result | `scan/presentation/pages/result_page.dart` | Done. |
| 4 · Report wrong label | `scan/presentation/pages/report_page.dart` | Done. |

## The labels come from the manifest

**The design canvas shows labels that the trained models do not have.** The coffee card
lists four rust severity levels. The trained model has 3 classes, because this copy of
RoCoLe puts the rust levels in one folder. The durian card lists 5 labels. The dataset has
6 folders.

Therefore every screen reads the labels from `manifest.json`. No screen holds a label in
its code. The card, the result list and the correction rows all follow the model that
runs. Three tests hold this rule:

- `model_card_test.dart` asserts 3 chips for coffee and 6 for durian.
- `report_page_test.dart` asserts 4 rows for coffee and 7 for durian.
- `scan_repository_impl_test.dart` asserts a failure when the count of logits differs
  from the count of labels.

## Set up the machine

```bash
brew tap leoafarias/fvm
brew install fvm
cd leaf-disease-mobile
fvm install
```

An Android build needs a JDK between 17 and 25:

```bash
fvm flutter config --jdk-dir=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home
```

The iOS deployment target is 16.0, because `flutter_onnxruntime` needs it.

## Commands

```bash
fvm flutter pub get                # install the packages
fvm flutter analyze                # run the static analysis
fvm flutter test                   # run the unit and widget tests
./scripts/run.sh                   # list the devices that are ready
./scripts/run.sh ios               # boot an iOS simulator and run the app
fvm flutter test integration_test/flow_test.dart -d <device-id>   # walk the app
```

The integration test runs the real models on a device. It proves that the ONNX files load
on the platform, which a widget test cannot show.

## The brand

The mark comes from the `Logo` artboard of the design: four scan brackets around a leaf
with one vein. The source files live in `assets/brand/`.

| File | Use |
|---|---|
| `app_icon.svg` | The source of the launcher icon. |
| `app_icon_foreground.svg` | The Android adaptive foreground. The mark sits inside the safe circle. |
| `app_icon.png` | The 1024 pixel render that the generator reads. |

`lib/core/widgets/leafscan_mark.dart` draws the same paths in the app, so the screen and
the icon never differ. Produce the launcher icons again after a change:

```bash
rsvg-convert -w 1024 -h 1024 assets/brand/app_icon.svg -o assets/brand/app_icon.png
rsvg-convert -w 1024 -h 1024 assets/brand/app_icon_foreground.svg \
  -o assets/brand/app_icon_foreground.png
fvm dart run flutter_launcher_icons
```

The app name is `LeafScan` on both platforms.

## The model files

See `assets/models/README.md`. Never commit a model file. Produce both files with
`tools/export_onnx.py`, then check them with `tools/verify_onnx.py`.

## State of the work

| Item | State |
|---|---|
| The six screens of the design | Done. |
| The app icon and the name | Done. Both platforms. |
| Clean Architecture with three layers for each feature | Done. |
| flutter_bloc for every screen | Done. |
| The coffee model and the durian model | Done. Both verified on real images. |
| 189 unit and widget tests, 3 integration tests | Done. All pass. |
| The model download over the network | Done. `GET /v1/crops`, then `GET /v1/devices/config`; SHA-256 checked; the previous version stays as the fallback; bundled models when nothing is released or the phone is offline. |
| The upload of an image and a score | Not started. Stage 3. |
| The Android SDK on this machine | Not installed. |
| Latency on a real low-performance Android phone | Not measured. |
