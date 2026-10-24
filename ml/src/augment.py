"""Training-time augmentation on landmark windows (never used at eval/export).

Operates on raw clips / metric windows so the augmented sample still goes
through the exact same `features.featurize` path as inference.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

import features as F


@dataclass(frozen=True)
class AugmentConfig:
    crop_min: float = 0.75  # keep at least this fraction of the clip
    warp: float = 0.5  # index jitter, in units of one resampling step
    drop_p: float = 0.05  # per-frame chance a hand detection is dropped
    mirror_p: float = 0.3
    rotate_deg: float = 12.0
    scale_range: float = 0.12
    noise_std: float = 0.01  # on normalized features


def _sample_indices(n: int, t: int, rng: np.random.Generator, cfg: AugmentConfig) -> np.ndarray:
    """Random temporal crop + jittered (time-warped) nearest-index sampling."""
    keep = rng.uniform(cfg.crop_min, 1.0)
    length = max(2.0, keep * n)
    start = rng.uniform(0.0, n - length)
    base = start + (np.arange(t) + 0.5) * length / t
    step = length / t
    jittered = np.sort(base + rng.uniform(-cfg.warp, cfg.warp, size=t) * step)
    return np.clip(np.floor(jittered), 0, n - 1).astype(np.int64)


def _geometry(win: F.Window, rng: np.random.Generator, cfg: AugmentConfig) -> F.Window:
    """Small in-plane rotation + uniform scale around the window centroid."""
    theta = np.deg2rad(rng.uniform(-cfg.rotate_deg, cfg.rotate_deg))
    scale = 1.0 + rng.uniform(-cfg.scale_range, cfg.scale_range)
    cos, sin = np.cos(theta) * scale, np.sin(theta) * scale
    rot = np.array([[cos, -sin], [sin, cos]], dtype=np.float32)

    present = np.arange(F.N_SLOTS)[None, :] < win.n_hands[:, None]
    wrists = win.hands[:, :, F.WRIST, :2][present]
    centre = wrists.mean(axis=0) if len(wrists) else np.array([win.width, win.height]) / 2

    hands = win.hands.copy()
    hands[..., :2] = (hands[..., :2] - centre) @ rot.T + centre
    hands[..., 2] *= scale
    pose = win.pose.copy()
    pose[..., :2] = (pose[..., :2] - centre) @ rot.T + centre
    pose[..., 2] *= scale
    return F.Window(hands, win.n_hands, pose, win.pose_ok, win.width, win.height)


def _drop_hands(win: F.Window, rng: np.random.Generator, cfg: AugmentConfig) -> F.Window:
    """Simulate missed detections by removing the last detected hand."""
    drop = (rng.random(win.n_hands.shape) < cfg.drop_p) & (win.n_hands > 0)
    n_hands = win.n_hands - drop.astype(np.int64)
    return F.Window(win.hands, n_hands, win.pose, win.pose_ok, win.width, win.height)


def augmented_features(
    clip: F.RawClip, t: int, variant: str, rng: np.random.Generator, cfg: AugmentConfig
) -> np.ndarray:
    win = F.to_window(clip, _sample_indices(clip.n_frames, t, rng, cfg))
    if rng.random() < cfg.mirror_p:
        win = F.mirror_window(win)
    win = _drop_hands(_geometry(win, rng, cfg), rng, cfg)
    feats = F.featurize(win, variant)
    if cfg.noise_std > 0:
        noise = rng.normal(0.0, cfg.noise_std, size=feats.shape).astype(np.float32)
        # Only perturb coordinate channels of present hands; masks stay binary.
        coord = np.zeros(feats.shape[1], dtype=bool)
        coord[: F.N_SLOTS * F.N_LM * 3] = True
        if variant == "B":
            coord[F.N_SLOTS * F.N_LM * 3 + F.N_SLOTS : -1] = True
        feats = feats + noise * coord * (feats != 0)
    return feats
