# Credits and licenses (ml/)

## FSL-105 dataset (CC-BY-4.0)

Training data comes from **FSL-105**, a video database of 105 introductory
Filipino Sign Language signs. It is licensed **CC-BY-4.0**; attribution is
required and is given here.

> Tupal, I. L. and Cabatuan, M. K., "FSL105: The Video Filipino Sign Language
> Sign Database of Introductory 105 FSL Signs," Mendeley Data, V2.
> https://data.mendeley.com/datasets/48y2y99mb9/2

The videos and any landmarks extracted from them are **not** committed
(`ml/data/` is gitignored). Only the trained model, label list and synthetic
test vectors in `ml/export/` are in the repository.

Please verify the exact author list and DOI on the dataset page before any
publication; they were not re-checked beyond the handoff document's citation.

## Models and libraries

- `hand_landmarker.task` and `pose_landmarker_full.task`: Google MediaPipe
  models (Apache-2.0). The hand model is the one bundled by the Flutter
  `hand_landmarker` plugin (MIT).
- MediaPipe, TensorFlow/Keras, NumPy, OpenCV, pandas, matplotlib: see
  `requirements.txt` for versions; each under its own open-source license.
