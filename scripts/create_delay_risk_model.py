from __future__ import annotations

from pathlib import Path

import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers


MODEL_PATH = Path("models/delay_risk_model.keras")
RANDOM_SEED = 42


def build_dataset(samples: int = 5000) -> tuple[np.ndarray, np.ndarray]:
    """Genera datos sintéticos explicables para una primera demo funcional.

    Features esperadas por IntelligentRoutingService:
    0. task age / average completion
    1. area backlog normalized
    2. missing required documents
    3. instance age normalized
    4. recent rejections
    """

    rng = np.random.default_rng(RANDOM_SEED)
    x = rng.uniform(0, 5, size=(samples, 5)).astype("float32")

    linear_score = (
        0.34 * x[:, 0]
        + 0.24 * x[:, 1]
        + 0.22 * x[:, 2]
        + 0.13 * x[:, 3]
        + 0.17 * x[:, 4]
    )

    # Curva suave 0..1 para simular probabilidad de demora.
    y = 1 / (1 + np.exp(-(linear_score - 2.55)))
    y = y.astype("float32")
    return x, y


def build_model() -> keras.Model:
    model = keras.Sequential(
        [
            layers.Input(shape=(5,), name="routing_features"),
            layers.Dense(16, activation="relu"),
            layers.Dropout(0.05),
            layers.Dense(8, activation="relu"),
            layers.Dense(1, activation="sigmoid", name="delay_risk"),
        ]
    )
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.008),
        loss="mse",
        metrics=["mae"],
    )
    return model


def main() -> None:
    np.random.seed(RANDOM_SEED)
    tf.random.set_seed(RANDOM_SEED)
    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)

    x, y = build_dataset()
    model = build_model()
    model.fit(
        x,
        y,
        epochs=14,
        batch_size=64,
        validation_split=0.15,
        verbose=1,
    )
    model.save(MODEL_PATH)
    print(f"Modelo TensorFlow guardado en: {MODEL_PATH.resolve()}")


if __name__ == "__main__":
    main()
