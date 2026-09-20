# Leaf Disease Mobile

The app runs the thesis leaf disease classifier on a phone. The app also closes the
active learning loop. The phone computes an uncertainty score. The app sends the image
and the score to the server. The server adds the image to the unlabelled pool.

The design document is `docs/superpowers/specs/2026-09-20-mobile-cv-app-design.md`.
Read it before you change the architecture.

## Stack

| Layer | Choice | Reason |
|---|---|---|
| App framework | Flutter 3.47.5 (Dart) | One codebase for Android and iOS. |
| SDK manager | fvm | The version is pinned in `.fvmrc`. The build is reproducible. |
| Inference | ONNX Runtime, `flutter_onnxruntime` | The export from PyTorch needs one step. |
| Model | FastViT-T8, INT8 | The thesis benchmark selected this model. |
| State | `flutter_riverpod` | It handles asynchronous state such as a download. |
| Network | `dio` | It reports download progress. It retries an upload. |

## Set up the machine

The project needs fvm. The Flutter version installs automatically.

```bash
brew tap leoafarias/fvm
brew install fvm
cd leaf-disease-mobile
fvm install
```

Android builds need a JDK between 17 and 25. This machine uses Temurin 21:

```bash
fvm flutter config --jdk-dir=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home
```

Check the state of the toolchain:

```bash
fvm flutter doctor
```

## Commands

```bash
fvm flutter pub get        # install the packages
fvm flutter analyze        # run the static analysis
fvm flutter test           # run the tests
fvm flutter run            # start the app on a connected device
```

Use the helper script to choose a target:

```bash
./scripts/run.sh           # list the devices that are ready
./scripts/run.sh ios       # boot an iOS simulator and run the app
./scripts/run.sh android   # boot an Android emulator and run the app
```

The script reports the missing component when a target is not ready. It prints the
command that installs the component.

## Simulator and emulator state

Xcode 26 does not include an iOS simulator runtime. Download it one time:

```bash
xcodebuild -downloadPlatform iOS
```

The download is about 9 GB. A real iPhone needs no download. A real low-performance
Android phone gives the latency numbers that the thesis report needs.

## Structure

```
lib/
  main.dart                  the entry point
  src/
    app.dart                 the root widget
    model/                   the manifest, the classifier and the scores
      model_manifest.dart    parses and validates a published manifest
      uncertainty.dart       softmax, entropy, least confidence and margin
    capture/                 the camera and the photo library
    upload/                  the observation queue and the API client
    ui/                      the screens and the widgets
test/
  model/                     the unit tests for the pure Dart code
docs/
  superpowers/specs/         the design documents
```

## Rules for a model file

Never commit a model file. `.gitignore` blocks `*.onnx` and `*.ort`.

A model file always travels with a manifest. The manifest holds the input size, the
normalization values and the label order. The app reads these values from the manifest.
The app does not hold them in its code. This rule prevents a silent failure after an
update.

## State of the work

| Item | State |
|---|---|
| The Flutter project and the toolchain | Done. |
| The design document | Done. |
| `ModelManifest` and `Uncertainty` with tests | Done. |
| `ModelStore`, `ModelUpdater`, `Preprocessor`, `Classifier` | Not started. |
| The capture screen and the result screen | Not started. |
| The upload queue and the consent screen | Not started. |
| The Android SDK on this machine | Not installed. |
| Xcode for the iOS build | Not installed. |
