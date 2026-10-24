"""Evaluation: top-1/top-5, per-class accuracy, confusion matrix image."""
from __future__ import annotations

import argparse
import json
import logging
from pathlib import Path

import keras
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402

import data as D  # noqa: E402
import features as F  # noqa: E402

LOG = logging.getLogger("evaluate")


def make_features(items: list[D.Item], t: int, variant: str) -> np.ndarray:
    return np.stack([F.clip_features(it.clip, t, variant) for it in items])


def metrics(probs: np.ndarray, labels: np.ndarray) -> dict:
    top1 = (probs.argmax(axis=1) == labels).mean()
    top5 = np.mean([lab in np.argsort(p)[-5:] for p, lab in zip(probs, labels)])
    return {"top1": float(top1), "top5": float(top5), "n": int(len(labels))}


def per_class(probs: np.ndarray, labels: np.ndarray, names: list[str]) -> pd.DataFrame:
    pred = probs.argmax(axis=1)
    rows = []
    for c, name in enumerate(names):
        mask = labels == c
        rows.append({"id": c, "label": name, "n": int(mask.sum()),
                     "accuracy": float((pred[mask] == c).mean()) if mask.any() else np.nan})
    return pd.DataFrame(rows)


def confusion(probs: np.ndarray, labels: np.ndarray, n: int) -> np.ndarray:
    cm = np.zeros((n, n), dtype=np.int32)
    for true, pred in zip(labels, probs.argmax(axis=1)):
        cm[true, pred] += 1
    return cm


def save_confusion_png(cm: np.ndarray, path: Path, title: str) -> None:
    norm = cm / np.maximum(cm.sum(axis=1, keepdims=True), 1)
    fig, ax = plt.subplots(figsize=(11, 10))
    im = ax.imshow(norm, cmap="Oranges", vmin=0, vmax=1)
    ax.set_xlabel("predicted sign id")
    ax.set_ylabel("true sign id")
    ax.set_title(title)
    fig.colorbar(im, ax=ax, fraction=0.046, label="row-normalized")
    fig.tight_layout()
    fig.savefig(path, dpi=110)
    plt.close(fig)


def evaluate_run(run: Path, split: str) -> dict:
    cfg = json.loads((run / "config.json").read_text())
    model = keras.saving.load_model(run / "model.keras")
    items = D.load_split("test.csv" if split == "test" else "train.csv")
    if split == "val":
        _, items = D.split_train_val(items, seed=cfg["split_seed"])
    labels = np.array([it.label for it in items])
    probs = model.predict(make_features(items, cfg["t"], cfg["variant"]), verbose=0)
    names = D.load_labels().label.tolist()
    result = metrics(probs, labels)
    out = run / f"eval_{split}"
    out.mkdir(exist_ok=True)
    per_class(probs, labels, names).to_csv(out / "per_class.csv", index=False)
    save_confusion_png(confusion(probs, labels, len(names)), out / "confusion.png",
                       f"{cfg['variant']} T={cfg['t']} {split} (top-1 {result['top1']:.3f})")
    (out / "metrics.json").write_text(json.dumps(result, indent=2))
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--run", type=Path, required=True)
    parser.add_argument("--split", choices=("val", "test"), default="test")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    LOG.info("%s", json.dumps(evaluate_run(args.run, args.split)))


if __name__ == "__main__":
    main()
