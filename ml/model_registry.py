from pathlib import Path
from typing import Any

from utils.logger import get_logger

logger = get_logger(__name__)


class ModelRegistry:
    """Carga modelos TensorFlow de forma opcional para no romper entornos locales."""

    def __init__(self, models_dir: str = "models") -> None:
        self._models_dir = Path(models_dir)
        self._delay_model: Any | None = None
        self._tensorflow_available: bool | None = None

    @property
    def tensorflow_available(self) -> bool:
        if self._tensorflow_available is None:
            try:
                import tensorflow  # noqa: F401

                self._tensorflow_available = True
            except Exception:
                self._tensorflow_available = False
        return self._tensorflow_available

    def model_status(self) -> str:
        if self._delay_model is not None:
            return "tensorflow_model_loaded"
        if self.tensorflow_available:
            return "tensorflow_available_without_trained_model"
        return "heuristic_fallback_tensorflow_not_installed"

    def predict_delay_risk(self, features: list[float]) -> float | None:
        model = self._load_delay_model()
        if model is None:
            return None
        try:
            import numpy as np

            input_vector = np.array([features], dtype="float32")
            prediction = model.predict(input_vector, verbose=0)
            return float(prediction[0][0])
        except Exception as exc:
            logger.warning("TensorFlow delay prediction failed, using fallback: %s", exc)
            return None

    def _load_delay_model(self) -> Any | None:
        if self._delay_model is not None:
            return self._delay_model
        if not self.tensorflow_available:
            return None

        model_path = self._models_dir / "delay_risk_model.keras"
        if not model_path.exists():
            return None

        try:
            from tensorflow import keras

            self._delay_model = keras.models.load_model(model_path)
            logger.info("TensorFlow delay model loaded from %s", model_path)
            return self._delay_model
        except Exception as exc:
            logger.warning("Could not load TensorFlow delay model from %s: %s", model_path, exc)
            return None
