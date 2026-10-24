"""Export the trained classifier for the app.

Writes to export/:
  model.tflite        float32, fixed input (1, T, D), built-in ops only
  feature_spec.json   everything Dart needs to rebuild the input tensor
  label_map.json      id -> English label (dataset labels)
  signs.json          id, en, fil (fil stays null until a reviewer confirms it)
  golden/             synthetic input -> features -> probabilities vectors
  parity.json         Keras vs TFLite agreement on real validation sequences

Golden inputs are synthetic on purpose: AGENTS.md forbids committing landmark
data of real people, so no recorded landmarks leave data/.
"""
from __future__ import annotations

import argparse
import json
import logging
from pathlib import Path

import keras
import numpy as np
import tensorflow as tf

import data as D
import features as F
from evaluate import make_features
from model import inference_copy

LOG = logging.getLogger("export")
ROOT = Path(__file__).resolve().parents[1]
EXPORT = ROOT / "export"
PARITY_SEQUENCES = 40
PARITY_TOLERANCE = 1e-3
GOLDEN_SIZE = (480, 640)  # portrait upright frame, like the phone preview


def convert(model: keras.Model, t: int, d: int, out: Path) -> bytes:
    """Keras -> float32 TFLite with weights frozen into constants.

    Freezing (instead of converting the SavedModel directly) avoids the
    VAR_HANDLE / CALL_ONCE / ASSIGN_VARIABLE stateful ops that older mobile
    TFLite runtimes handle poorly; the result is a pure feed-forward graph.
    """
    from tensorflow.python.framework.convert_to_constants import (
        convert_variables_to_constants_v2,
    )

    fn = tf.function(lambda x: model(x, training=False)).get_concrete_function(
        tf.TensorSpec((1, t, d), tf.float32)
    )
    frozen = convert_variables_to_constants_v2(fn)
    converter = tf.lite.TFLiteConverter.from_concrete_functions([frozen], model)
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]  # no Flex ops
    blob = converter.convert()
    out.write_bytes(blob)
    return blob


def tflite_predict(blob: bytes, x: np.ndarray) -> np.ndarray:
    interpreter = tf.lite.Interpreter(model_content=blob)
    interpreter.allocate_tensors()
    inp, out = interpreter.get_input_details()[0], interpreter.get_output_details()[0]
    rows = []
    for sample in x:
        interpreter.set_tensor(inp["index"], sample[None].astype(np.float32))
        interpreter.invoke()
        rows.append(interpreter.get_tensor(out["index"])[0].copy())
    return np.stack(rows)


def _hand_template() -> np.ndarray:
    """A crude 21-point hand skeleton (normalized units); not real anatomy data."""
    pts = np.zeros((21, 3), dtype=np.float32)
    for finger in range(5):
        base_x = (finger - 2) * 0.012
        for joint in range(4):
            idx = 1 + finger * 4 + joint
            pts[idx] = (base_x * (1 + 0.3 * joint), -0.02 - 0.022 * (joint + 1) - 0.004 * finger,
                        -0.004 * joint)
    return pts


def synthetic_clip(kind: str, seed: int, frames: int = 90) -> F.RawClip:
    """Deterministic fake landmark sequences covering the slotting branches."""
    rng = np.random.default_rng(seed)
    tmpl = _hand_template()
    hands = np.zeros((frames, 2, 21, 3), dtype=np.float32)
    n_hands = np.zeros(frames, dtype=np.int8)
    for f in range(frames):
        phase = f / frames
        shown = {"two": 2, "right_only": 1, "left_only": 1, "mixed": 2 if 0.3 < phase < 0.7 else 1,
                 "dropout": 2}[kind]
        if kind == "dropout" and f % 7 in (3, 4):
            shown = 1 if f % 2 else 0
        for h in range(shown):
            side = {"right_only": 0.3, "left_only": 0.7}.get(kind, 0.3 if h == 0 else 0.7)
            angle = 0.3 * np.sin(2 * np.pi * phase + h)
            rot = np.array([[np.cos(angle), -np.sin(angle)], [np.sin(angle), np.cos(angle)]])
            pts = tmpl.copy()
            pts[:, :2] = pts[:, :2] @ rot.T
            pts[:, :2] += [side + 0.05 * np.sin(2 * np.pi * phase * (1 + h)),
                           0.5 - 0.15 * phase]
            pts += rng.normal(0, 0.0008, pts.shape).astype(np.float32)
            hands[f, h] = pts
        n_hands[f] = shown
    # The plugin returns detection order, which is arbitrary: shuffle 2-hand frames.
    for f in np.flatnonzero(n_hands == 2):
        if rng.random() < 0.5:
            hands[f] = hands[f, ::-1]
    pose = np.zeros((frames, len(F.POSE_IDX), 4), dtype=np.float32)
    return F.RawClip(hands, n_hands, pose, np.zeros(frames, dtype=bool), *GOLDEN_SIZE)


def write_golden(model: keras.Model, blob: bytes, t: int, variant: str) -> list[str]:
    golden = EXPORT / "golden"
    golden.mkdir(parents=True, exist_ok=True)
    names = []
    for i, kind in enumerate(("two", "right_only", "left_only", "mixed", "dropout")):
        clip = synthetic_clip(kind, seed=100 + i)
        feats = F.clip_features(clip, t, variant)
        keras_probs = model.predict(feats[None], verbose=0)[0]
        tfl_probs = tflite_predict(blob, feats[None])[0]
        sample = {
            "name": kind,
            "width": clip.width, "height": clip.height, "t": t, "variant": variant,
            "raw_frames": [clip.hands[f, : int(clip.n_hands[f])].tolist() for f in range(clip.n_frames)],
            "features": feats.tolist(),
            "probs_keras": keras_probs.tolist(),
            "probs_tflite": tfl_probs.tolist(),
        }
        (golden / f"{kind}.json").write_text(json.dumps(sample))
        names.append(kind)
    return names


def write_metadata(t: int, variant: str, names: list[str]) -> None:
    labels = D.load_labels()
    (EXPORT / "label_map.json").write_text(json.dumps(
        {str(r.id): r.label for r in labels.itertuples()}, indent=2, ensure_ascii=False))
    (EXPORT / "signs.json").write_text(json.dumps(
        [{"id": int(r.id), "en": r.label, "fil": None, "category": r.category}
         for r in labels.itertuples()], indent=2, ensure_ascii=False))
    spec = {
        "variant": variant, "t": t, "feature_dim": F.feature_dim(variant),
        "input_shape": [1, t, F.feature_dim(variant)], "dtype": "float32",
        "hand_block": "slot0 (21x[x,y,z]) | slot1 (21x[x,y,z]) | present0 | present1",
        "constants": {"WRIST": F.WRIST, "MIDDLE_MCP": F.MIDDLE_MCP, "EPS": F.EPS},
        "golden": names,
        "doc": "ml/README.md#feature-contract",
    }
    (EXPORT / "feature_spec.json").write_text(json.dumps(spec, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run", type=Path, required=True, help="runs/<variant>_T<t>_s<seed>")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(message)s")

    cfg = json.loads((args.run / "config.json").read_text())
    if cfg["variant"] != "A":
        raise SystemExit("Only Variant A can ship: the app has no pose pipeline yet.")
    t, d = cfg["t"], cfg["feature_dim"]
    trained = keras.saving.load_model(args.run / "model.keras")
    model = inference_copy(trained, t, d, units=cfg["units"])
    probe = np.random.default_rng(1).normal(size=(8, t, d)).astype(np.float32)
    if not np.allclose(trained.predict(probe, verbose=0), model.predict(probe, verbose=0), atol=1e-5):
        raise SystemExit("inference copy does not match the trained model")

    EXPORT.mkdir(exist_ok=True)
    blob = convert(model, t, d, EXPORT / "model.tflite")
    LOG.info("model.tflite: %d bytes", len(blob))

    _, val = D.split_train_val(D.load_split("train.csv"), seed=cfg["split_seed"])
    pick = np.random.default_rng(0).permutation(len(val))[:PARITY_SEQUENCES]
    x = make_features([val[i] for i in pick], t, "A")
    keras_probs = model.predict(x, verbose=0)
    tfl_probs = tflite_predict(blob, x)
    diff = float(np.abs(keras_probs - tfl_probs).max())
    parity = {"sequences": int(len(x)), "max_abs_diff": diff, "tolerance": PARITY_TOLERANCE,
              "passed": bool(diff < PARITY_TOLERANCE),
              "argmax_agreement": float((keras_probs.argmax(1) == tfl_probs.argmax(1)).mean())}
    test_items = D.load_split("test.csv")
    test_probs = tflite_predict(blob, make_features(test_items, t, "A"))
    test_labels = np.array([it.label for it in test_items])
    parity["tflite_test_top1"] = float((test_probs.argmax(1) == test_labels).mean())
    parity["tflite_test_n"] = int(len(test_items))
    (EXPORT / "parity.json").write_text(json.dumps(parity, indent=2))
    LOG.info("parity: %s", json.dumps(parity))

    names = write_golden(model, blob, t, "A")
    write_metadata(t, "A", names)
    if not parity["passed"]:
        raise SystemExit("TFLite parity check FAILED")


if __name__ == "__main__":
    main()
