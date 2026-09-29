# Model assets

This folder holds the models that ship with the app.

```
assets/models/
  catalog.json        the list of models the picker shows
  coffee/
    manifest.json     in git
    model.onnx        not in git
  durian/
    manifest.json     in git
    model.onnx        not in git
```

`.gitignore` blocks `*.onnx`. A model file is 13 MB and it changes every round.

## Produce the model files

Run both commands from the root of this project.

```bash
../active-learning/.venv/bin/python tools/export_onnx.py \
  --checkpoint ../leaf-disease-active-learning-package/checkpoints/fastvit_t8/fold_1_best.pt \
  --output assets/models/coffee/model.onnx

../active-learning/.venv/bin/python tools/export_onnx.py \
  --checkpoint ../leaf-disease-active-learning-package/checkpoints/durian_fastvit_t8/fold_3_best.pt \
  --output assets/models/durian/model.onnx
```

## Check a model before you ship it

```bash
../active-learning/.venv/bin/python tools/verify_onnx.py \
  --model assets/models/durian/model.onnx \
  --manifest assets/models/durian/manifest.json \
  --data ../leaf-disease-active-learning-package/raw_data/durian/val --per-class 5
```

Measured on 2026-09-29: coffee 22 of 24 on training images, durian 30 of 30 on
validation images.

## The labels

The label order decides which output index is which class. Do not sort the list.

| Model | Labels | Source of the order |
|---|---|---|
| Coffee | 3 | `class_names` in `active-learning/configs/rocole.yaml` |
| Durian | 6 | the folder names under `raw_data/durian/train`, sorted |

**The design canvas shows different labels.** The coffee card lists four rust levels and
the durian card lists five labels. The trained models do not have those classes. Every
screen reads the labels from the manifest, so the screen always agrees with the model.
