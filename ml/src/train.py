"""Train one configuration (variant x T x seed) and save it under runs/."""
from __future__ import annotations

import argparse
import json
import logging
import time
from pathlib import Path

import keras
import numpy as np

import augment as A
import data as D
import features as F
from evaluate import make_features, metrics
from model import build_model

LOG = logging.getLogger("train")
ROOT = Path(__file__).resolve().parents[1]


def augmented_epoch(items: list[D.Item], t: int, variant: str, rng: np.random.Generator,
                    cfg: A.AugmentConfig) -> np.ndarray:
    return np.stack([A.augmented_features(it.clip, t, variant, rng, cfg) for it in items])


def train(variant: str, t: int, seed: int, epochs: int, out: Path, split_seed: int = 0,
          patience: int = 25, units: int = 96) -> dict:
    keras.utils.set_random_seed(seed)
    rng = np.random.default_rng(seed)

    train_items, val_items = D.split_train_val(D.load_split("train.csv"), seed=split_seed)
    y_train = np.array([it.label for it in train_items])
    y_val = np.array([it.label for it in val_items])
    x_val = make_features(val_items, t, variant)

    model = build_model(t, F.feature_dim(variant), units=units)
    steps = epochs * int(np.ceil(len(train_items) / 64))
    schedule = keras.optimizers.schedules.CosineDecay(2e-3, steps, alpha=0.02)
    model.compile(
        optimizer=keras.optimizers.Adam(schedule),
        loss=keras.losses.SparseCategoricalCrossentropy(),
        metrics=["accuracy"],
    )

    cfg = A.AugmentConfig()
    best, best_epoch, best_weights, history = -1.0, 0, None, []
    started = time.time()
    for epoch in range(1, epochs + 1):
        x_train = augmented_epoch(train_items, t, variant, rng, cfg)
        fit = model.fit(x_train, y_train, batch_size=64, epochs=1, verbose=0, shuffle=True)
        val = metrics(model.predict(x_val, verbose=0), y_val)
        history.append({"epoch": epoch, "loss": float(fit.history["loss"][0]), **val})
        if val["top1"] > best:
            best, best_epoch, best_weights = val["top1"], epoch, model.get_weights()
        if epoch % 5 == 0 or epoch == 1:
            LOG.info("%s T=%d s=%d epoch %d loss %.3f val top1 %.3f (best %.3f @%d) %.0fs",
                     variant, t, seed, epoch, history[-1]["loss"], val["top1"], best,
                     best_epoch, time.time() - started)
        if epoch - best_epoch >= patience:
            break

    model.set_weights(best_weights)
    out.mkdir(parents=True, exist_ok=True)
    model.save(out / "model.keras")
    config = {"variant": variant, "t": t, "seed": seed, "epochs_run": len(history),
              "best_epoch": best_epoch, "split_seed": split_seed, "units": units,
              "feature_dim": F.feature_dim(variant), "val_top1": best,
              "augment": A.AugmentConfig().__dict__}
    (out / "config.json").write_text(json.dumps(config, indent=2))
    (out / "history.json").write_text(json.dumps(history))
    return config


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--variant", choices=F.VARIANTS, required=True)
    parser.add_argument("--t", type=int, default=48, choices=(32, 48, 64))
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument("--epochs", type=int, default=120)
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    out = args.out or ROOT / "runs" / f"{args.variant}_T{args.t}_s{args.seed}"
    LOG.info("%s", json.dumps(train(args.variant, args.t, args.seed, args.epochs, out)))


if __name__ == "__main__":
    main()
