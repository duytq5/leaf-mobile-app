#!/usr/bin/env python3
"""Check an exported ONNX model on real images.

The script repeats the evaluation transform of the training code. It then runs
the ONNX model and prints the predicted class for each image. Run it after
every export. A wrong preprocessing step gives a low accuracy without an error.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import onnxruntime as ort
from PIL import Image

IMAGENET_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
IMAGENET_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


def preprocess(path: Path, resize_shortest: int, crop: int) -> np.ndarray:
    """Resize the shortest side, crop the centre, scale and normalize."""
    image = Image.open(path).convert("RGB")
    width, height = image.size
    if width < height:
        new_size = (resize_shortest, round(height * resize_shortest / width))
    else:
        new_size = (round(width * resize_shortest / height), resize_shortest)
    image = image.resize(new_size, Image.BILINEAR)

    left = round((image.width - crop) / 2)
    top = round((image.height - crop) / 2)
    image = image.crop((left, top, left + crop, top + crop))

    array = np.asarray(image, dtype=np.float32) / 255.0
    array = (array - IMAGENET_MEAN) / IMAGENET_STD
    return np.transpose(array, (2, 0, 1))[None, ...].astype(np.float32)


def softmax(logits: np.ndarray) -> np.ndarray:
    shifted = logits - logits.max()
    exponentials = np.exp(shifted)
    return exponentials / exponentials.sum()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", type=Path, default=Path("assets/models/model.onnx"))
    parser.add_argument(
        "--manifest", type=Path, default=Path("assets/models/manifest.json")
    )
    parser.add_argument(
        "--data", type=Path, required=True, help="a folder with one folder per class"
    )
    parser.add_argument("--per-class", type=int, default=10)
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text())
    labels = manifest["labels"]
    spec = manifest["input"]
    crop = spec["width"]
    resize_shortest = spec.get("resize_shortest", crop)

    session = ort.InferenceSession(str(args.model), providers=["CPUExecutionProvider"])
    input_name = session.get_inputs()[0].name

    total = 0
    correct = 0
    print(f"{'true class':<28} {'predicted':<28} conf")
    print("-" * 66)

    for index, label in enumerate(labels):
        folder = args.data / label
        if not folder.is_dir():
            print(f"warning: {folder} is absent")
            continue

        images = sorted(folder.glob("*.jpg"))[: args.per_class]
        for path in images:
            tensor = preprocess(path, resize_shortest, crop)
            logits = session.run(None, {input_name: tensor})[0][0]
            probabilities = softmax(logits)
            predicted = int(probabilities.argmax())
            total += 1
            correct += predicted == index
            mark = " " if predicted == index else "X"
            print(
                f"{mark} {label:<26} {labels[predicted]:<28} "
                f"{probabilities[predicted]:.3f}"
            )

    if total:
        print("-" * 66)
        print(f"accuracy on {total} images: {correct / total:.1%}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
