"""Extract per-frame MediaPipe landmarks from FSL-105 clips.

Mirrors the Android plugin (hand_landmarker 2.2.0): same hand_landmarker.task
model, IMAGE running mode, 2 hands, min detection confidence 0.7, frame
JPEG-round-tripped at quality 100 like the plugin does, and coordinates left
exactly as MediaPipe returns them (normalized, upright, NOT mirrored).

Output: data/landmarks/<class>_<clip>.npz (gitignored; landmark data is
sensitive and must never be committed).
"""
from __future__ import annotations

import argparse
import logging
import os
import urllib.request
from multiprocessing import Pool
from pathlib import Path

import cv2
import numpy as np
import pandas as pd

from features import N_LM, POSE_IDX

LOG = logging.getLogger("extract")
ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
OUT = ROOT / "data" / "landmarks"
MODELS = ROOT / "models"
HAND_MODEL = MODELS / "hand_landmarker.task"
POSE_MODEL = MODELS / "pose_landmarker_full.task"
POSE_URL = (
    "https://storage.googleapis.com/mediapipe-models/pose_landmarker/"
    "pose_landmarker_full/float16/latest/pose_landmarker_full.task"
)
PLUGIN_MODEL_GLOB = (
    "Pub/Cache/hosted/pub.dev/hand_landmarker-2.2.0/android/src/main/assets/"
    "hand_landmarker.task"
)

# Settings copied from lib/services/landmark_service.dart.
NUM_HANDS = 2
MIN_HAND_DETECTION = 0.7

_hand = None
_pose = None


def ensure_models() -> None:
    MODELS.mkdir(exist_ok=True)
    if not HAND_MODEL.exists():
        src = Path(os.environ.get("LOCALAPPDATA", "")) / PLUGIN_MODEL_GLOB
        if not src.exists():
            raise FileNotFoundError(
                f"Copy hand_landmarker.task from the Flutter plugin ({PLUGIN_MODEL_GLOB}) "
                f"to {HAND_MODEL}"
            )
        HAND_MODEL.write_bytes(src.read_bytes())
        LOG.info("copied hand model from plugin assets")
    if not POSE_MODEL.exists():
        LOG.info("downloading %s", POSE_URL)
        urllib.request.urlretrieve(POSE_URL, POSE_MODEL)  # noqa: S310 (fixed https URL)


def _init_worker() -> None:
    global _hand, _pose
    from mediapipe.tasks import python as mp_python
    from mediapipe.tasks.python import vision

    mode = vision.RunningMode.IMAGE
    _hand = vision.HandLandmarker.create_from_options(
        vision.HandLandmarkerOptions(
            base_options=mp_python.BaseOptions(model_asset_path=str(HAND_MODEL)),
            running_mode=mode,
            num_hands=NUM_HANDS,
            min_hand_detection_confidence=MIN_HAND_DETECTION,
        )
    )
    _pose = vision.PoseLandmarker.create_from_options(
        vision.PoseLandmarkerOptions(
            base_options=mp_python.BaseOptions(model_asset_path=str(POSE_MODEL)),
            running_mode=mode,
            num_poses=1,
        )
    )


def _jpeg_roundtrip(bgr: np.ndarray) -> np.ndarray:
    ok, buf = cv2.imencode(".jpg", bgr, [cv2.IMWRITE_JPEG_QUALITY, 100])
    return cv2.imdecode(buf, cv2.IMREAD_COLOR) if ok else bgr


def extract_clip(args: tuple[str, str, int, bool]) -> tuple[str, int, str]:
    """Process one video. Returns (name, n_frames, status)."""
    import mediapipe as mp

    video, name, stride, with_pose = args
    out_path = OUT / f"{name}.npz"
    if out_path.exists():
        return name, -1, "skipped"
    cap = cv2.VideoCapture(video)
    if not cap.isOpened():
        return name, 0, "cannot open video"
    fps = float(cap.get(cv2.CAP_PROP_FPS) or 0.0)

    hands, n_hands, pose, pose_ok = [], [], [], []
    width = height = 0
    index = 0
    while True:
        ok, bgr = cap.read()
        if not ok:
            break
        if index % stride:
            index += 1
            continue
        index += 1
        height, width = bgr.shape[:2]
        rgb = cv2.cvtColor(_jpeg_roundtrip(bgr), cv2.COLOR_BGR2RGB)
        image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

        frame_hands = np.zeros((2, N_LM, 3), dtype=np.float32)
        result = _hand.detect(image)
        for i, lms in enumerate(result.hand_landmarks[:2]):
            frame_hands[i] = [(p.x, p.y, p.z) for p in lms]
        hands.append(frame_hands)
        n_hands.append(min(len(result.hand_landmarks), 2))

        frame_pose = np.zeros((len(POSE_IDX), 4), dtype=np.float32)
        found = False
        if with_pose:
            presult = _pose.detect(image)
            if presult.pose_landmarks:
                lms = presult.pose_landmarks[0]
                frame_pose = np.array(
                    [(lms[j].x, lms[j].y, lms[j].z, lms[j].visibility) for j in POSE_IDX],
                    dtype=np.float32,
                )
                found = True
        pose.append(frame_pose)
        pose_ok.append(found)
    cap.release()

    if not hands:
        return name, 0, "no frames"
    OUT.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(
        out_path,
        hands=np.stack(hands),
        n_hands=np.array(n_hands, dtype=np.int8),
        pose=np.stack(pose),
        pose_ok=np.array(pose_ok, dtype=bool),
        size=np.array([width, height], dtype=np.int32),
        fps=np.float32(fps / stride),
    )
    return name, len(hands), "ok"


def clip_name(vid_path: str) -> str:
    parts = Path(vid_path.replace("\\", "/")).parts
    return f"{parts[-2]}_{Path(parts[-1]).stem}"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workers", type=int, default=6)
    parser.add_argument("--stride", type=int, default=1, help="keep every Nth frame")
    parser.add_argument("--no-pose", action="store_true", help="skip Variant B pose")
    parser.add_argument("--limit", type=int, default=0, help="only first N clips (smoke test)")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")

    ensure_models()
    frames = pd.concat([pd.read_csv(RAW / "train.csv"), pd.read_csv(RAW / "test.csv")])
    jobs = []
    for vid in frames.vid_path:
        path = RAW / vid.replace("\\", "/")
        if not path.exists():
            raise FileNotFoundError(f"{path} missing; unzip data/raw/clips.zip into data/raw/")
        jobs.append((str(path), clip_name(vid), args.stride, not args.no_pose))
    if args.limit:
        jobs = jobs[: args.limit]

    # Fail fast in the parent: a broken mediapipe install would otherwise kill
    # every pool worker at startup and leave imap_unordered waiting forever.
    _init_worker()

    done = 0
    with Pool(args.workers, initializer=_init_worker) as pool:
        for name, n, status in pool.imap_unordered(extract_clip, jobs, chunksize=4):
            done += 1
            if status not in ("ok", "skipped"):
                LOG.warning("%s: %s", name, status)
            if done % 50 == 0 or done == len(jobs):
                LOG.info("%d/%d clips", done, len(jobs))


if __name__ == "__main__":
    main()
