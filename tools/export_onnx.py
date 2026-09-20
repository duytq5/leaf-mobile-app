#!/usr/bin/env python3
"""Export a trained FastViT checkpoint to ONNX for the mobile app.

The script performs three steps.

1. It builds the timm model and loads the checkpoint.
2. It calls reparameterize_model. FastViT trains with multi-branch blocks. The
   call folds these blocks into single convolutions. The folded model is faster
   and gives the same output.
3. It writes the ONNX file.

Run it with the training environment:

    active-learning/.venv/bin/python tools/export_onnx.py \
        --checkpoint <path>/fold_1_best.pt \
        --output assets/models/model.onnx
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

import torch
import timm
from timm.utils.model import reparameterize_model


def infer_num_classes(state: dict) -> int:
    """Read the class count from the classifier weight of the checkpoint."""
    for key, value in reversed(list(state.items())):
        if key.endswith(".weight") and "head" in key and value.dim() == 2:
            return int(value.shape[0])
    raise SystemExit("error: the script cannot find the classifier weight.")


def load_state(path: Path) -> dict:
    """Load a checkpoint. It holds a state dict or a wrapper around one."""
    raw = torch.load(path, map_location="cpu", weights_only=False)
    if isinstance(raw, dict):
        for key in ("state_dict", "model", "model_state_dict"):
            if key in raw and isinstance(raw[key], dict):
                return raw[key]
    return raw


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--checkpoint", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--model-name", default="fastvit_t8")
    parser.add_argument("--resolution", type=int, default=256)
    parser.add_argument(
        "--opset", type=int, default=17, help="the ONNX opset version"
    )
    parser.add_argument(
        "--skip-reparameterize",
        action="store_true",
        help="export the multi-branch model. Use it only to compare the output.",
    )
    args = parser.parse_args()

    if not args.checkpoint.is_file():
        raise SystemExit(f"error: {args.checkpoint} is not a file.")

    state = load_state(args.checkpoint)
    n_classes = infer_num_classes(state)
    print(f"the checkpoint has {n_classes} classes")

    model = timm.create_model(
        args.model_name, pretrained=False, num_classes=n_classes
    )
    missing, unexpected = model.load_state_dict(state, strict=False)
    if missing:
        print(f"warning: {len(missing)} absent keys, first: {missing[:3]}")
    if unexpected:
        print(f"warning: {len(unexpected)} extra keys, first: {unexpected[:3]}")
    model.eval()

    example = torch.randn(1, 3, args.resolution, args.resolution)

    with torch.no_grad():
        reference = model(example)

    if args.skip_reparameterize:
        print("the script does not fold the branches")
        exported = model
    else:
        exported = reparameterize_model(model)
        exported.eval()
        with torch.no_grad():
            folded = exported(example)
        difference = (reference - folded).abs().max().item()
        print(f"the largest difference after the fold is {difference:.2e}")
        if difference > 1e-3:
            raise SystemExit(
                "error: the fold changes the output. Do not use this file."
            )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with torch.no_grad():
        torch.onnx.export(
            exported,
            example,
            str(args.output),
            input_names=["input"],
            output_names=["logits"],
            opset_version=args.opset,
            dynamo=False,
        )

    size = args.output.stat().st_size
    digest = hashlib.sha256(args.output.read_bytes()).hexdigest()
    print(f"wrote {args.output} ({size / 1e6:.1f} MB)")
    print(f"sha256 {digest}")

    manifest = args.output.parent / "manifest.json"
    if manifest.is_file():
        data = json.loads(manifest.read_text())
        labels = data.get("labels", [])
        if len(labels) != n_classes:
            print(
                f"warning: the manifest lists {len(labels)} labels but the "
                f"model returns {n_classes} values. Correct the manifest.",
                file=sys.stderr,
            )
        else:
            print(f"the manifest matches: {n_classes} labels")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
