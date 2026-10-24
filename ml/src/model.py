"""Model definition shared by training, evaluation and export."""
from __future__ import annotations

import keras
from keras import layers

N_CLASSES = 105


def build_model(t: int, d: int, units: int = 96, dropout: float = 0.3,
                head_dropout: float = 0.4) -> keras.Model:
    """Two stacked GRUs -> softmax over 105 signs.

    `unroll=True` keeps the graph static (fixed T) so TFLite converts it with
    built-in ops only; T is small (<= 64) so the unrolled graph stays cheap.
    """
    inputs = keras.Input(shape=(t, d), name="features")
    x = layers.GRU(units, return_sequences=True, unroll=True, dropout=dropout)(inputs)
    x = layers.GRU(units, unroll=True, dropout=dropout)(x)
    if head_dropout > 0:
        x = layers.Dropout(head_dropout)(x)
    outputs = layers.Dense(N_CLASSES, activation="softmax", name="probs")(x)
    return keras.Model(inputs, outputs, name="fsl105_gru")


def inference_copy(trained: keras.Model, t: int, d: int, units: int = 96) -> keras.Model:
    """Dropout-free copy with the trained weights, for export.

    Keras dropout keeps a seed-generator variable in the graph even at
    inference, which turns into stateful TFLite ops. The copy has none.
    """
    clone = build_model(t, d, units=units, dropout=0.0, head_dropout=0.0)
    # Match by name: the trained model has an extra Dropout layer the clone lacks.
    for dst in clone.layers:
        if dst.get_weights():
            dst.set_weights(trained.get_layer(dst.name).get_weights())
    return clone
