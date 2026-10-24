"""Report split structure and video properties (used for the README findings)."""
import cv2
import pandas as pd

from extract_landmarks import RAW, clip_name

tr, te = pd.read_csv(RAW / "train.csv"), pd.read_csv(RAW / "test.csv")
for d in (tr, te):
    d["n"] = d.vid_path.map(lambda v: int(clip_name(v).rsplit("_", 1)[1]))
print("clip index range train", tr.n.min(), tr.n.max(), "test", te.n.min(), te.n.max())
print("clip indices present in both:", len(set(tr.n) & set(te.n)), "of", te.n.nunique())
print("per-class train", tr.groupby("id_label").size().agg(["min", "max"]).tolist(),
      "test", te.groupby("id_label").size().agg(["min", "max"]).tolist())
print("duplicate paths across splits:", len(set(tr.vid_path) & set(te.vid_path)))
print("test clips per index:", te.groupby("n").size().to_dict())
print("train clips per index:", tr.groupby("n").size().to_dict())
for p in ("clips/0/0.MOV", "clips/50/7.MOV", "clips/104/3.MOV"):
    c = cv2.VideoCapture(str(RAW / p))
    print(p, "w", c.get(3), "h", c.get(4), "fps", c.get(5), "frames", c.get(7),
          "orient", c.get(cv2.CAP_PROP_ORIENTATION_META))
