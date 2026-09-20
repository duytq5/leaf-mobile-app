# Model assets

This folder holds the model that ships with the app.

| File | State | Source |
|---|---|---|
| `manifest.json` | In git. | Written by hand. It matches `active-learning/configs/rocole.yaml`. |
| `model.onnx` | Not in git. | Produced by `tools/export_onnx.py`. |

`.gitignore` blocks `*.onnx`. A model file is large and it changes every round.

## Produce the model file

```bash
python tools/export_onnx.py \
  --checkpoint ../leaf-disease-active-learning-package/checkpoints/fastvit_t8/fold_1_best.pt \
  --output assets/models/model.onnx
```

## The values in the manifest

The values repeat the evaluation transform of the training code
(`active-learning/src/leafal/data/transforms.py`):

- `Resize(int(256 * 256 / 224))` gives `resize_shortest: 292`.
- `CenterCrop(256)` gives `width: 256` and `height: 256`.
- `Normalize(IMAGENET_MEAN, IMAGENET_STD)` gives `mean` and `std`.

The label order comes from `class_names` in `configs/rocole.yaml`. The order decides
which output index is which class. Do not sort the list.
