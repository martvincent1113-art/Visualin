"""Properties the Dart port must also satisfy (ml/README.md, Feature contract)."""
import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

import features as F  # noqa: E402
from export_tflite import synthetic_clip  # noqa: E402


def clip(kind: str = "two", seed: int = 1) -> F.RawClip:
    return synthetic_clip(kind, seed)


def test_resample_indices_cover_clip_in_order() -> None:
    idx = F.resample_indices(245, 48)
    assert idx.shape == (48,) and idx.min() >= 0 and idx.max() <= 244
    assert np.all(np.diff(idx) >= 0)


def test_resample_short_clip_repeats_frames() -> None:
    assert F.resample_indices(10, 32).max() == 9


@pytest.mark.parametrize("kind", ["two", "right_only", "left_only", "mixed", "dropout"])
def test_variant_a_shape_and_masks(kind: str) -> None:
    feats = F.clip_features(clip(kind), 48, "A")
    assert feats.shape == (48, 128) and feats.dtype == np.float32
    masks = feats[:, -2:]
    assert set(np.unique(masks)) <= {0.0, 1.0}
    absent = masks == 0
    # An absent hand must be exactly zero coordinates.
    coords = feats[:, :126].reshape(48, 2, 63)
    assert np.all(coords[absent] == 0)


def test_empty_window_is_all_zero() -> None:
    c = clip("two")
    c.n_hands[:] = 0
    assert not F.clip_features(c, 32, "A").any()


def test_translation_and_scale_invariant() -> None:
    c = clip("two")
    base = F.clip_features(c, 48, "A")
    moved = F.RawClip(c.hands.copy(), c.n_hands, c.pose, c.pose_ok, c.width, c.height)
    active = np.arange(2)[None, :] < c.n_hands[:, None]
    moved.hands[..., :2][active] = moved.hands[..., :2][active] * 0.7 + 0.1
    moved.hands[..., 2][active] *= 0.7
    assert np.allclose(F.clip_features(moved, 48, "A"), base, atol=1e-4)


def test_detection_order_does_not_matter() -> None:
    c = clip("two")
    swapped = F.RawClip(c.hands[:, ::-1].copy(), c.n_hands, c.pose, c.pose_ok, c.width, c.height)
    assert np.allclose(F.clip_features(swapped, 48, "A"), F.clip_features(c, 48, "A"), atol=1e-6)


def test_mirror_twice_is_identity() -> None:
    win = F.to_window(clip("mixed"), F.resample_indices(90, 48))
    twice = F.mirror_window(F.mirror_window(win))
    assert np.allclose(twice.hands, win.hands, atol=1e-4)
    assert np.allclose(twice.pose, win.pose, atol=1e-4)


def test_single_hand_slot_follows_side_of_frame() -> None:
    left = F.slot_hands(F.to_window(clip("right_only"), np.arange(30)))[1]
    right = F.slot_hands(F.to_window(clip("left_only"), np.arange(30)))[1]
    assert left[:, 0].all() and not left[:, 1].any()
    assert right[:, 1].all() and not right[:, 0].any()


def test_aspect_ratio_does_not_distort_scale() -> None:
    # The same pixel-space scene seen through a wide and a tall frame (centres
    # aligned) must give identical features: x*W / y*H removes the anisotropy.
    c = clip("right_only")
    wide_px = np.array([640.0, 360.0, 640.0], dtype=np.float32)
    tall_px = np.array([360.0, 640.0, 360.0], dtype=np.float32)
    metric = c.hands * wide_px
    tall = metric.copy()
    tall[..., :2] += (tall_px[:2] - wide_px[:2]) / 2.0
    wide_clip = F.RawClip(c.hands, c.n_hands, c.pose, c.pose_ok, 640, 360)
    tall_clip = F.RawClip((tall / tall_px).astype(np.float32), c.n_hands, c.pose,
                          c.pose_ok, 360, 640)
    a = F.clip_features(wide_clip, 32, "A")
    b = F.clip_features(tall_clip, 32, "A")
    assert np.allclose(a, b, atol=1e-3)


def test_variant_b_dim() -> None:
    assert F.feature_dim("B") == 150
    assert F.clip_features(clip("two"), 32, "B").shape == (32, 150)
