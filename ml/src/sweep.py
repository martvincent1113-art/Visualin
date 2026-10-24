"""Experiment driver: T sweep, then 3 seeds at each variant's best T.

Selection (T, early stopping) uses the validation split carved from train.
Test numbers are only read after selection and are reported for every run so
nothing is hidden.
"""
from __future__ import annotations

import argparse
import json
import logging
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np

import features as F
from evaluate import evaluate_run

LOG = logging.getLogger("sweep")
ROOT = Path(__file__).resolve().parents[1]
RUNS = ROOT / "runs"
REPORTS = ROOT / "reports"
T_VALUES = (32, 48, 64)
SEEDS = (0, 1, 2)


def run_name(variant: str, t: int, seed: int) -> str:
    return f"{variant}_T{t}_s{seed}"


def ensure_run(variant: str, t: int, seed: int, epochs: int) -> Path:
    out = RUNS / run_name(variant, t, seed)
    if (out / "model.keras").exists():
        return out
    cmd = [sys.executable, str(Path(__file__).with_name("train.py")), "--variant", variant,
           "--t", str(t), "--seed", str(seed), "--epochs", str(epochs), "--out", str(out)]
    LOG.info("training %s", out.name)
    subprocess.run(cmd, check=True)
    return out


def summarize(values: list[float]) -> dict:
    return {"mean": float(np.mean(values)), "std": float(np.std(values)), "runs": values}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--epochs", type=int, default=120)
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    REPORTS.mkdir(exist_ok=True)

    sweep: dict[str, dict[int, dict]] = {}
    for variant in F.VARIANTS:
        sweep[variant] = {}
        for t in T_VALUES:
            run = ensure_run(variant, t, 0, args.epochs)
            val = evaluate_run(run, "val")
            test = evaluate_run(run, "test")
            sweep[variant][t] = {"val": val, "test": test}

    best_t = {v: max(T_VALUES, key=lambda t: sweep[v][t]["val"]["top1"]) for v in F.VARIANTS}
    final: dict[str, dict] = {}
    for variant in F.VARIANTS:
        t = best_t[variant]
        runs = [ensure_run(variant, t, seed, args.epochs) for seed in SEEDS]
        val = [evaluate_run(r, "val") for r in runs]
        test = [evaluate_run(r, "test") for r in runs]
        best_idx = int(np.argmax([v["top1"] for v in val]))
        final[variant] = {
            "t": t, "best_run": runs[best_idx].name,
            "val_top1": summarize([v["top1"] for v in val]),
            "test_top1": summarize([r["top1"] for r in test]),
            "test_top5": summarize([r["top5"] for r in test]),
        }

    gap = final["B"]["test_top1"]["mean"] - final["A"]["test_top1"]["mean"]
    results = {"t_sweep": sweep, "best_t": best_t, "final": final, "gap_B_minus_A_test_top1": gap}
    (REPORTS / "results.json").write_text(json.dumps(results, indent=2))

    primary = RUNS / final["A"]["best_run"] / "eval_test"
    shutil.copy(primary / "confusion.png", REPORTS / "confusion_variant_A.png")
    shutil.copy(primary / "per_class.csv", REPORTS / "per_class_variant_A.csv")
    LOG.info("results written to %s", REPORTS / "results.json")


if __name__ == "__main__":
    main()
