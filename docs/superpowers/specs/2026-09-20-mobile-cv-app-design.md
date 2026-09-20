# Mobile leaf disease app - design

Date: 2026-09-20. Revised 2026-09-21 to reduce the scope.
Status: stage 1 is approved. The later stages are a record only.

## 1. Stage 1 - the only scope now

The app does three things.

1. The user selects an image from the camera or from the photo library.
2. The app runs FastViT-T8 on the image.
3. The app shows the class and the confidence.

One screen. No navigation. No accounts. No upload. No model download.

The user interface is not a subject of this document. A plain list of results is enough.

## 2. Out of scope for stage 1

The later stages keep these items. Stage 1 does not build them.

| Item | Stage |
|---|---|
| The model download over the network | 2 |
| The upload of an image and a score to the server | 3 |
| The consent screen and the upload queue | 3 |
| The rollback of a failed model | 2 |
| The camera preview and a capture screen | later, if needed |

## 3. Stage 1 components

| Component | Purpose | State |
|---|---|---|
| `ImagePickerSource` | Returns the bytes of a selected image. | To write. |
| `Preprocessor` | Converts the bytes to a normalized tensor. | To write. |
| `Classifier` | Runs the ONNX model. Returns the probabilities. | To write. |
| `Uncertainty` | Computes entropy, least confidence and margin. | Done. Tested. |
| `ModelManifest` | Holds the input size, the normalization and the labels. | Done. Tested. |
| `ResultScreen` | Shows the class and the confidence. | To write. |

`ModelManifest` stays in stage 1. The app reads a small `manifest.json` from the assets
next to the model file. This costs almost nothing now. It prevents a silent failure when
stage 2 adds the model download.

## 4. The model file

The app needs an ONNX file. The training project holds a PyTorch checkpoint:
`leaf-disease-active-learning-package/checkpoints/fastvit_t8/fold_1_best.pt`.

The export has three steps. The script `tools/export_onnx.py` performs them.

1. Load the checkpoint. Call `reparameterize_model()`. FastViT trains with multi-branch
   blocks. The function folds these blocks into single convolutions. The folded model is
   faster and gives the same output.
2. Export with `torch.onnx.export` and a fixed input shape.
3. Write `manifest.json` with the input size, the normalization values and the labels.

Stage 1 uses the float model. Add the INT8 quantization after the first latency
measurement shows a need.

## 5. The manifest

```json
{
  "model_id": "fastvit_t8_rocole",
  "version": "fold-1-best",
  "input": {
    "width": 256,
    "height": 256,
    "layout": "NCHW",
    "mean": [0.485, 0.456, 0.406],
    "std": [0.229, 0.224, 0.225]
  },
  "labels": ["healthy", "rust", "red_spider_mite", "cercospora", "leaf_miner"]
}
```

The stage 2 fields `file_url`, `sha256`, `bytes` and `min_app_build` are absent in the
asset manifest. The parser accepts a manifest without them.

## 6. Data flow

```
photo library or camera
   |  bytes
   v
Preprocessor  (decode, resize to 256x256, normalize with the manifest values)
   |  Float32List, NCHW
   v
Classifier    (ONNX Runtime, XNNPACK on the CPU)
   |  logits
   v
softmax -> top class + confidence -> ResultScreen
```

## 7. Error handling for stage 1

| Failure | Response of the app |
|---|---|
| The user cancels the picker. | The app stays on the screen. |
| The image decode fails. | The app shows a message. The app asks for a new image. |
| The model file is absent. | The app shows a clear message at the start. |
| The model fails to load. | The app shows the error text. The app does not crash. |

## 8. Testing for stage 1

| Level | Target |
|---|---|
| Unit | `Preprocessor`, `Uncertainty`, `ModelManifest` |
| Widget | `ResultScreen` with a fixed prediction |
| Manual | A real image on a simulator and on a phone |

The `Classifier` needs a device. A manual test covers it.

## 9. Performance notes to keep

These apply when the latency becomes a subject. Stage 1 records the numbers only.

- Call `reparameterize_model()` before the export.
- Decode the image at a small size.
- Run the inference in a Dart isolate.
- Load the model one time. Keep the session.
- Measure p50 and p95 on a real low-performance Android phone, not on a simulator.
