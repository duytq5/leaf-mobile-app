# Mobile leaf disease app - design

Date: 2026-09-20
Status: approved for bootstrap. The implementation plan is not written yet.

## 1. Purpose

The app runs the thesis leaf disease classifier on a phone. The app also closes the
active learning loop. The phone computes an uncertainty score for each image. The app
sends the image and the score to the server. The server adds the image to the unlabelled
pool. The acquisition function selects from that pool for the next round.

## 2. Scope

The app is the deployment stage of the master thesis. The audience is the thesis
committee and a small group of field testers. The app is not a product for an app store.

In scope:

- The app classifies an image from the camera or from the photo library.
- The app downloads a new model over the network.
- The app runs on Android and on iOS.
- The app runs on a low-performance device.
- The app uploads an image and an uncertainty score to the server.

Out of scope:

- User accounts and authentication of a person.
- Analytics and crash reporting services.
- On-device training or on-device fine-tuning.
- Offline map data, multi-language text, and accessibility audits.

## 3. Model

The thesis benchmark selected FastViT-T8. FastViT is a hybrid model. It combines
convolution blocks and attention blocks. Apple designed FastViT for mobile hardware.

### 3.1 Export

The export runs in the existing Python project. The export has three steps.

1. Call `reparameterize_model()` on the trained model. FastViT trains with multi-branch
   blocks. The function folds these branches into single convolutions. The folded model
   is faster. It gives the same output.
2. Export the folded model with `torch.onnx.export`. Use a fixed input shape.
3. Quantize the ONNX file to INT8. Use static post-training quantization. Calibrate with
   images from the current labelled pool.

**Warning:** measure the accuracy per class after quantization. The research question is
about rare classes. Quantization reduces the accuracy of a rare class first. Record the
per-class accuracy of the float model and the INT8 model in the thesis report.

### 3.2 Runtime

The app uses ONNX Runtime through the `flutter_onnxruntime` package. The package is
active. It had 28 releases since April 2025. The last release is from 2026-09-08.

The runtime uses the XNNPACK execution provider on the CPU. XNNPACK is the reliable
choice on a low-performance device. Core ML and NNAPI are optional. Add them only after a
measurement shows a benefit.

## 4. Architecture

```
Phone                                   Server (existing Python project)
-----                                   --------------------------------
camera or photo library
   |
   v
preprocess (resize, normalize)
   |
   v
ONNX Runtime + FastViT-T8  -----------> POST /observations
   |                                       image + logits + uncertainty
   v                                          |
show the class and the confidence             v
   |                                    unlabelled pool
   v                                          |
GET /models/manifest.json <-----------  acquisition -> retrain -> publish
GET /models/<file>.onnx
```

## 5. Components

Each component has one purpose. Each component has a small interface. You can test each
component alone.

| Component | Purpose | Depends on |
|---|---|---|
| `ModelManifest` | Holds the model version, the file URL, the hash, the input spec and the labels. | Nothing. Pure Dart. |
| `ModelStore` | Stores model files on the device. Performs an atomic swap and a rollback. | `path_provider` |
| `ModelUpdater` | Reads the manifest. Downloads a file. Verifies the hash. Installs the file. | `ModelStore`, `dio` |
| `Preprocessor` | Converts an image to a normalized tensor. Follows the manifest input spec. | `image` |
| `Classifier` | Runs the model. Returns the class probabilities. | `flutter_onnxruntime` |
| `Uncertainty` | Computes entropy, least confidence and margin from the probabilities. | Nothing. Pure Dart. |
| `UploadQueue` | Holds observations while the device is offline. Retries a failed upload. | `dio` |
| `ConsentStore` | Records the consent of the user before the first upload. | `shared_preferences` |

## 6. The manifest

The manifest travels with the model. The app does not hold the preprocessing values in
its code.

```json
{
  "model_id": "fastvit_t8_rocole",
  "version": "al-round-07",
  "file_url": "https://<host>/models/fastvit_t8_al07_int8.onnx",
  "sha256": "<64 hex characters>",
  "bytes": 3211264,
  "input": {
    "width": 256,
    "height": 256,
    "layout": "NCHW",
    "mean": [0.485, 0.456, 0.406],
    "std": [0.229, 0.224, 0.225]
  },
  "labels": ["healthy", "rust", "red_spider_mite", "cercospora", "leaf_miner"],
  "min_app_build": 1
}
```

**Reason for this design:** a model update changes the normalization values or the label
order. If the app holds these values in its code, the update breaks the output. The
failure looks like a bad model. The real cause is a mismatch. The manifest removes this
failure.

## 7. The update procedure

1. The app starts. The app loads the model that is active now.
2. The app requests the manifest. The app uses a timeout of 10 seconds.
3. The app compares the manifest version with the installed version.
4. If the versions are equal, the app stops here.
5. If `min_app_build` is higher than the app build, the app shows a message. The app
   stops here.
6. The app downloads the file to a temporary path.
7. The app computes the SHA-256 hash of the file.
8. If the hash is different, the app deletes the file. The app keeps the old model.
9. If the hash is correct, the app moves the file into the model directory.
10. The app writes the new manifest. The app keeps the previous model and manifest.
11. The app loads the new model at the next start.

The app always ships with a baseline model in `assets/models/`. The app works offline on
the first run.

### 7.1 Rollback

The app keeps one previous model. The app rolls back when the new model fails to load.
The app records the failure. The app reports the failure with the next upload.

## 8. The upload contract

`POST /observations` with a multipart body.

| Field | Type | Purpose |
|---|---|---|
| `image` | file | The original image. The app does not send the resized tensor. |
| `model_version` | string | The model version that produced the prediction. |
| `logits` | float list | The raw output of the model. |
| `entropy` | float | The predictive entropy. |
| `least_confidence` | float | One minus the highest probability. |
| `margin` | float | The difference between the two highest probabilities. |
| `captured_at` | ISO 8601 | The capture time on the device. |
| `source` | enum | `camera` or `library`. |
| `device_model` | string | The device name. Use it for the latency analysis. |

The server sends the original image, not the resized tensor. A later round can use a
different input size. The original image keeps that option open.

The app asks for consent before the first upload. The app records the consent date. The
app shows a switch to stop all uploads.

## 9. Error handling

| Failure | Response of the app |
|---|---|
| The network is not available. | The app uses the installed model. The app adds the observation to the upload queue. |
| The manifest request fails. | The app uses the installed model. The app retries at the next start. |
| The hash does not match. | The app deletes the file. The app keeps the old model. The app logs the event. |
| The model fails to load. | The app rolls back to the previous model. |
| The image decode fails. | The app shows a message. The app asks for a new image. |
| The upload fails. | The queue holds the observation. The app retries with a backoff. |

## 10. Performance on a low-performance device

| Action | Reason |
|---|---|
| Call `reparameterize_model()` before the export. | The folded model is faster. Many people forget this step. |
| Quantize the model to INT8. | The file is about 4 times smaller. The CPU inference is about 2 times faster. |
| Decode the image at a small size. | A full-size decode uses a large amount of memory. |
| Run the inference in a Dart isolate. | The user interface stays responsive. |
| Use one centre crop. Do not use test-time augmentation. | Each extra crop adds a full inference. |
| Load the model one time. Keep the session. | A session creation costs hundreds of milliseconds. |

### 10.1 Measurements to record

Record these numbers on a real low-performance Android device. The thesis report needs
them.

- The cold start time to the first prediction.
- The inference latency. Record p50 and p95.
- The peak memory use.
- The model file size.
- The per-class accuracy of the float model and of the INT8 model.

## 11. Testing

| Level | Target | Tool |
|---|---|---|
| Unit | `Uncertainty`, `ModelManifest`, `Preprocessor` | `flutter_test` |
| Unit with a fake | `ModelUpdater`, `UploadQueue` | `mocktail` |
| Widget | The result screen and the update screen | `flutter_test` |
| Manual | The camera, the photo library, a real device | A test script in `docs/` |

The pure Dart components need no device. They run in the normal test suite.

## 12. Open decisions

| Decision | Status |
|---|---|
| The Android SDK install method. | Open. The machine has no Android SDK. |
| The iOS build. | Open. The machine has the Command Line Tools only. Xcode is necessary. |
| The server host for the manifest and the models. | Open. |
| The state management package. | Decided. The project uses `flutter_riverpod`. |
