"""Dataset loading: provided FSL-105 split + a validation split carved from train."""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd

import features as F
from extract_landmarks import clip_name

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
LANDMARKS = ROOT / "data" / "landmarks"
N_CLASSES = 105


@dataclass
class Item:
    name: str
    label: int
    clip_index: int  # the <n> in clips/<class>/<n>.MOV
    clip: F.RawClip


def load_labels() -> pd.DataFrame:
    return pd.read_csv(RAW / "labels.csv", encoding="utf-8-sig")


def load_clip(name: str) -> F.RawClip:
    with np.load(LANDMARKS / f"{name}.npz") as z:
        width, height = (int(v) for v in z["size"])
        return F.RawClip(
            hands=z["hands"], n_hands=z["n_hands"].astype(np.int64),
            pose=z["pose"], pose_ok=z["pose_ok"], width=width, height=height,
        )


def load_split(csv: str) -> list[Item]:
    frame = pd.read_csv(RAW / csv)
    items = []
    for vid, label in zip(frame.vid_path, frame.id_label):
        name = clip_name(vid)
        index = int(name.rsplit("_", 1)[1])
        items.append(Item(name, int(label), index, load_clip(name)))
    return items


def split_train_val(items: list[Item], val_fraction: float = 0.2, seed: int = 0):
    """Validation split taken from the provided train set (test stays untouched).

    The dataset ships no signer IDs, so the split is stratified by class only:
    every class keeps ~val_fraction of its clips for validation. See README
    "Signer independence" for why this is optimistic for model selection.
    """
    rng = np.random.default_rng(seed)
    by_class: dict[int, list[int]] = {}
    for i, item in enumerate(items):
        by_class.setdefault(item.label, []).append(i)
    val_idx: set[int] = set()
    for idxs in by_class.values():
        idxs = list(idxs)
        rng.shuffle(idxs)
        val_idx.update(idxs[: max(1, round(len(idxs) * val_fraction))])
    train = [it for i, it in enumerate(items) if i not in val_idx]
    val = [it for i, it in enumerate(items) if i in val_idx]
    return train, val
