from __future__ import annotations

from typing import TYPE_CHECKING

from PySide6.QtCore import QObject, QThread, Signal

# import app modules
from data import db
from utility import qt_util, save

if TYPE_CHECKING:
    import argparse
    from collections.abc import Callable


class Worker(QObject):
    finished = Signal()

    def __init__(self, task_name: str = "generic_task") -> None:
        super().__init__()
        self.task_name = task_name

    def run(self) -> None:
        """Run the worker main task. Work to be run within the new thread.

        Must emit finished signal when complete.
        """


class InitializationWorker(Worker):
    step_changed = Signal(str)
    init_finished = Signal(bool)

    def __init__(self, *, temp_instance: bool) -> None:
        super().__init__("Initialization")
        self._temp_instance = temp_instance

    def run(self) -> None:
        """Run the initialization steps."""
        self.step_changed.emit("Initializing user data")
        save.instantiate(self._temp_instance)

        self.step_changed.emit("Initializing database")
        db.initialize()

        self.init_finished.emit(True)  # noqa: FBT003

        self.finished.emit()


class AppController(QObject):
    def __init__(self) -> None:
        super().__init__()
        self._current_init_step = ""
        self._init_status = False

        self._threads: dict[str, QThread] = {}
        self._workers: dict[str, Worker] = {}

    # current initialization step property
    current_init_step, _get_current_init_step, _set_current_init_step, init_step_changed = (
        qt_util.qt_property(
            str,
            "current_init_step",
            "init_step_changed",
        )
    )

    # initialization status property
    init_status, _get_init_status, _set_init_status, init_status_changed = qt_util.qt_property(
        bool,
        "init_status",
        "init_status_changed",
    )

    def _start_task(
        self,
        task_worker: Worker,
        signal_connections: dict[str, Callable[..., None]] | None = None,
    ) -> None:
        """Start a task based on the given worker."""
        # Create worker and thread
        thread = QThread()
        worker = task_worker

        self._threads[worker.task_name] = thread
        self._workers[worker.task_name] = worker

        # Move worker to thread
        worker.moveToThread(thread)

        # set up connections
        thread.started.connect(worker.run)
        worker.finished.connect(thread.quit)
        worker.finished.connect(worker.deleteLater)
        worker.finished.connect(thread.deleteLater)

        # Connect worker signals to controller methods
        if signal_connections:
            for signal_name, handler in signal_connections.items():
                if hasattr(task_worker, signal_name):
                    getattr(task_worker, signal_name).connect(handler)

        def cleanup_references() -> None:
            del self._threads[worker.task_name]
            del self._workers[worker.task_name]

        thread.finished.connect(cleanup_references)

        # start thread
        thread.start()

    def start_initialization(self, command_line_args: argparse.Namespace) -> None:
        """Start the initialization process."""
        # Create the initialization worker
        init_worker = InitializationWorker(
            temp_instance=command_line_args.temp_instance,
        )

        # Start the task
        self._start_task(
            init_worker,
            {"step_changed": self._set_current_init_step, "init_finished": self._set_init_status},
        )

    def cleanup(self) -> None:
        """Prepare application for exit."""
        db.close_db()
