"""Feature contract for FSL sign classification (single source of truth).

Everything here is plain numpy so the Dart side can reproduce it line by line.
See ml/README.md "Feature contract" for the rationale behind each step.

Pipeline (deterministic, no learned parameters):

    raw clip (F frames, plugin-convention landmarks)
      -> resample to T frames (nearest index)
      -> metric space (x*W, y*H, z*W)  -- aspect-ratio safe
      -> slot hands (2 slots, canonical left-to-right order)
      -> window-level translate + scale normalization
      -> (T, D) float32 features

Variant A (on-device today): hands only, D = 2*21*3 + 2 = 128.
Variant B (offline experiment): A's hand block normalized to the shoulders,
plus 7 upper-body pose points and a pose-present flag, D = 128 + 21 + 1 = 150.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

N_SLOTS = 2
N_LM = 21
WRIST = 0
MIDDLE_MCP = 9

# MediaPipe Pose indices kept for Variant B: nose, shoulders, elbows, wrists.
POSE_IDX = (0, 11, 12, 13, 14, 15, 16)
# Positions inside POSE_IDX of the left/right pairs, swapped when mirroring.
POSE_SWAP = ((1, 2), (3, 4), (5, 6))
LEFT_SHOULDER, RIGHT_SHOULDER = 1, 2  # positions inside POSE_IDX
POSE_VIS_MIN = 0.5

EPS = 1e-6
VARIANTS = ("A", "B")


def feature_dim(variant: str) -> int:
    hands = N_SLOTS * N_LM * 3 + N_SLOTS
    if variant == "A":
        return hands
    if variant == "B":
        return hands + len(POSE_IDX) * 3 + 1
    raise ValueError(f"unknown variant {variant!r}")


@dataclass
class RawClip:
    """Landmarks exactly as the plugin returns them, one entry per frame.

    hands:   (F, 2, 21, 3) normalized x, y in [0, 1] of the upright,
             un-mirrored frame; z in the same units as x (wrist ~ 0).
             Detection order, unused slots are zero.
    n_hands: (F,) number of valid entries in `hands[f]`.
    pose:    (F, 7, 4) x, y, z, visibility for POSE_IDX (Variant B only).
    pose_ok: (F,) bool, whether a pose was detected.
    width, height: pixel size of the upright frame the coordinates refer to.
    """

    hands: np.ndarray
    n_hands: np.ndarray
    pose: np.ndarray
    pose_ok: np.ndarray
    width: int
    height: int

    @property
    def n_frames(self) -> int:
        return int(self.hands.shape[0])


@dataclass
class Window:
    """T frames in metric (pixel-like) space, detection order for hands."""

    hands: np.ndarray  # (T, 2, 21, 3)
    n_hands: np.ndarray  # (T,)
    pose: np.ndarray  # (T, 7, 3)
    pose_ok: np.ndarray  # (T,) bool
    width: float
    height: float


def resample_indices(n_frames: int, t: int) -> np.ndarray:
    """Nearest-index resampling: floor((i + 0.5) * n / t)."""
    if n_frames <= 0:
        raise ValueError("clip has no frames")
    idx = np.floor((np.arange(t) + 0.5) * n_frames / t).astype(np.int64)
    return np.clip(idx, 0, n_frames - 1)


def to_window(clip: RawClip, idx: np.ndarray) -> Window:
    """Select frames and convert to metric space (x*W, y*H, z*W)."""
    w, h = float(clip.width), float(clip.height)
    scale = np.array([w, h, w], dtype=np.float32)
    hands = clip.hands[idx].astype(np.float32) * scale
    pose = clip.pose[idx][..., :3].astype(np.float32) * scale
    pose_ok = clip.pose_ok[idx].astype(bool)
    vis = clip.pose[idx][..., 3]
    pose_ok = pose_ok & (vis[:, LEFT_SHOULDER] >= POSE_VIS_MIN) & (
        vis[:, RIGHT_SHOULDER] >= POSE_VIS_MIN
    )
    return Window(hands, clip.n_hands[idx].astype(np.int64), pose, pose_ok, w, h)


def mirror_window(win: Window) -> Window:
    """Horizontal flip in metric space (x -> W - x); swaps left/right pose."""
    hands = win.hands.copy()
    hands[..., 0] = win.width - hands[..., 0]
    pose = win.pose.copy()
    pose[..., 0] = win.width - pose[..., 0]
    for a, b in POSE_SWAP:
        pose[:, [a, b]] = pose[:, [b, a]]
    return Window(hands, win.n_hands, pose, win.pose_ok, win.width, win.height)


def slot_hands(win: Window) -> tuple[np.ndarray, np.ndarray]:
    """Place detected hands into 2 slots, slot 0 = leftmost in the image.

    The plugin returns hands in arbitrary order and no handedness, so order is
    derived from geometry only:
      * two hands in a frame: smaller wrist x goes to slot 0;
      * one hand: compare with the divider. The divider is the mean midpoint of
        the two wrists over two-hand frames of the window, else W/2. If the
        window never has two hands at once, all single-hand frames use the
        window-mean wrist x so the slot cannot flip mid-sign.
    Returns (hands (T, 2, 21, 3), present (T, 2) bool).
    """
    t = win.hands.shape[0]
    out = np.zeros_like(win.hands)
    present = np.zeros((t, N_SLOTS), dtype=bool)
    wrist_x = win.hands[:, :, WRIST, 0]

    pair = win.n_hands >= 2
    if pair.any():
        divider = float(wrist_x[pair, :2].mean())
    else:
        divider = win.width / 2.0

    single = win.n_hands == 1
    if single.any() and not pair.any():
        single_slot = 0 if float(wrist_x[single, 0].mean()) < divider else 1
    else:
        single_slot = None

    for f in range(t):
        n = int(win.n_hands[f])
        if n >= 2:
            a, b = (0, 1) if wrist_x[f, 0] <= wrist_x[f, 1] else (1, 0)
            out[f, 0], out[f, 1] = win.hands[f, a], win.hands[f, b]
            present[f] = True
        elif n == 1:
            slot = single_slot
            if slot is None:
                slot = 0 if wrist_x[f, 0] < divider else 1
            out[f, slot] = win.hands[f, 0]
            present[f, slot] = True
    return out, present


def _hand_scale(hands: np.ndarray, present: np.ndarray) -> float:
    """Mean wrist -> middle-finger-MCP distance (2D) over present hands."""
    if not present.any():
        return 1.0
    d = hands[..., MIDDLE_MCP, :2] - hands[..., WRIST, :2]
    s = float(np.linalg.norm(d, axis=-1)[present].mean())
    return s if s > EPS else 1.0


def featurize(win: Window, variant: str) -> np.ndarray:
    """Metric-space window -> (T, D) float32 feature matrix."""
    hands, present = slot_hands(win)
    t = hands.shape[0]
    feats = np.zeros((t, feature_dim(variant)), dtype=np.float32)
    if not present.any():
        return feats  # nothing detected: all zeros, all masks 0

    # Variant A reference: mean wrist position and mean hand size of the window.
    ref_xy = hands[..., WRIST, :2][present].mean(axis=0)
    scale = _hand_scale(hands, present)

    shoulders_ok = False
    if variant == "B" and win.pose_ok.any():
        ls = win.pose[win.pose_ok, LEFT_SHOULDER, :2]
        rs = win.pose[win.pose_ok, RIGHT_SHOULDER, :2]
        width = float(np.linalg.norm(ls - rs, axis=-1).mean())
        if width > EPS:
            ref_xy = ((ls + rs) / 2.0).mean(axis=0)
            scale = width
            shoulders_ok = True

    norm = hands.copy()
    norm[..., :2] = (hands[..., :2] - ref_xy) / scale
    norm[..., 2] = hands[..., 2] / scale
    norm[~present] = 0.0

    feats[:, : N_SLOTS * N_LM * 3] = norm.reshape(t, -1)
    feats[:, N_SLOTS * N_LM * 3 : N_SLOTS * N_LM * 3 + N_SLOTS] = present

    if variant == "B" and shoulders_ok:
        pose = win.pose.copy()
        pose[..., :2] = (pose[..., :2] - ref_xy) / scale
        pose[..., 2] = pose[..., 2] / scale
        pose[~win.pose_ok] = 0.0
        base = N_SLOTS * N_LM * 3 + N_SLOTS
        feats[:, base : base + len(POSE_IDX) * 3] = pose.reshape(t, -1)
        feats[:, -1] = win.pose_ok
    return feats


def clip_features(clip: RawClip, t: int, variant: str) -> np.ndarray:
    """Deterministic (evaluation / export) path: raw clip -> (T, D)."""
    return featurize(to_window(clip, resample_indices(clip.n_frames, t)), variant)
