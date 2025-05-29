"""Manages application data storage location, exposes data folder path."""

from __future__ import annotations

import atexit
import logging
import shutil
import sys
import tempfile
from pathlib import Path

logger = logging.getLogger(__name__)


class State:
    def __init__(self) -> None:
        self.production_mode = not sys.argv[0].endswith(".py")
        self._data_folder_path: Path | None = None
        self._DEV_DATA_FOLDER = ".dev_data"
        self._PROD_DATA_FOLDER = "data"
        self._INVALID_PATH_ACCESS_MSG = "Tried to access data folder path before instantiation."
        self._TEMP_PREFIX = "pfm_temp_"
        self._logger_configured = False
        self._file_handler: logging.FileHandler | None = None

    @property
    def data_folder_path(self) -> Path:
        """Get the data folder path."""
        if not self._data_folder_path:
            raise RuntimeError(self._INVALID_PATH_ACCESS_MSG)

        return self._data_folder_path

    def _configure_root_logger(self) -> None:
        if self._logger_configured:  # Avoid race condition
            return

        self._logger_configured = True

        # Get root logger
        root_logger = logging.getLogger()

        # Determine log level based on production mode
        level = logging.DEBUG if not self.production_mode else logging.INFO

        # Set log level
        root_logger.setLevel(level)

        # Create formater
        formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")

        # Create console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(level)
        console_handler.setFormatter(formatter)

        # Create file handler
        file_handler = logging.FileHandler(
            filename=self.data_folder_path / "pfm.log",
            encoding="utf-8",
        )
        file_handler.setLevel(level)
        file_handler.setFormatter(formatter)

        # Store file handler for release
        self._file_handler = file_handler

        # Add handlers to root logger
        root_logger.addHandler(console_handler)
        root_logger.addHandler(file_handler)

    def _release_log_file(self) -> None:
        if self._file_handler:
            self._file_handler.close()
            logging.getLogger().removeHandler(self._file_handler)

    def _cleanup_temp(self) -> None:
        """Cleanup any temporary files created by the application."""
        # Release log file to not interfere with cleanup
        self._release_log_file()

        # Remove temporary files created by the application
        temp_location = Path(tempfile.gettempdir())
        for app_temp_folder in temp_location.glob(f"{self._TEMP_PREFIX}*"):
            shutil.rmtree(app_temp_folder)

    def instantiate(self, temp_instance: bool | None) -> None:
        """Establish saved data location. If temp is true, data will not be saved.

        Also configures the root logger based on the saved data location.
        """
        if self._data_folder_path:
            logger.warning("Save already instantiated. Skipping re-initialization.")
            return

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

        # configure root logger after establishing data folder path
        self._configure_root_logger()

        # Show debug message with data folder path
        logger.debug("Save instantiated at location: %s", self._data_folder_path)


_state = State()


def data_folder_path() -> Path:
    """Get the data folder path."""
    return _state.data_folder_path


production_mode = _state.production_mode

instantiate = _state.instantiate
