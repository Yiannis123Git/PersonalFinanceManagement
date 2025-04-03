"""Manages application data storage location, exposes data folder path."""

from __future__ import annotations

import atexit
import shutil
import sys
import tempfile
from pathlib import Path


class State:
    def __init__(self) -> None:
        self.production_mode = not sys.argv[0].endswith(".py")
        self._data_folder_path: Path | None = None
        self._DEV_DATA_FOLDER = ".dev-data"
        self._PROD_DATA_FOLDER = "data"
        self._INVALID_PATH_ACCESS_MSG = (
            "Tried to access data folder path before instantiation."
        )
        self._ALREADY_ASTABLISHED_MSG = "Data folder path already established."
        self._TEMP_PREFIX = "pfm_temp_"

    @property
    def data_folder_path(self) -> Path:
        """Get the data folder path."""
        if not self._data_folder_path:
            raise RuntimeError(self._INVALID_PATH_ACCESS_MSG)

        return self._data_folder_path

    def _cleanup_temp(self) -> None:
        """Cleanup any temporary files created by the application."""
        temp_location = Path(tempfile.gettempdir())
        for app_temp_folder in temp_location.glob(f"{self._TEMP_PREFIX}*"):
            shutil.rmtree(app_temp_folder)

    def instantiate(self, temp_instance: bool | None) -> None:
        """Establish saved data location. If temp is true, data will not be saved."""
        if self._data_folder_path:
            raise RuntimeError(self._ALREADY_ASTABLISHED_MSG)

        # Get initial data folder path
        data_folder_path = Path("_")

        if not self.production_mode:
            # Running in development environment:

            # get project root path
            current_path = Path(__file__).parent
            while True:
                if current_path.name == "src":
                    break
                current_path = current_path.parent

            data_folder_path = current_path.parent / self._DEV_DATA_FOLDER
        else:
            # Running in production environment:
            data_folder_path = Path(sys.executable).parent / self._PROD_DATA_FOLDER

        if not temp_instance:
            if not data_folder_path.exists():
                data_folder_path.mkdir(exist_ok=True)

            self._data_folder_path = data_folder_path
        else:
            # Create a temporary instance of the application:
            temp_dir = Path(tempfile.mkdtemp(prefix=self._TEMP_PREFIX))

            # Copy already existing data
            if data_folder_path.exists():
                for item in data_folder_path.iterdir():
                    if item.is_dir():
                        shutil.copytree(item, temp_dir / item.name)
                    else:
                        shutil.copy2(item, temp_dir / item.name)

            self._data_folder_path = temp_dir

        # perform temp cleanup on exit
        atexit.register(self._cleanup_temp)


_state = State()


def data_folder_path() -> Path:
    """Get the data folder path."""
    return _state.data_folder_path


production_mode = _state.production_mode

instantiate = _state.instantiate
