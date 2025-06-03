from __future__ import annotations

from pathlib import Path  # noqa: TC003
from typing import TYPE_CHECKING

from PySide6.QtCore import Property, QObject, QThread, Signal, Slot

# import app modules
from data import db, monthly_gen
from gen import excel_gen, graph_gen
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

        self.step_changed.emit("Ensuring transaction data is up to date")
        monthly_gen.gen_transactions_for_all()

        self.init_finished.emit(True)  # noqa: FBT003

        self.finished.emit()


class AppController(QObject):
    def __init__(self) -> None:
        super().__init__()
        self._current_init_step = ""
        self._init_status = False

        self._threads: dict[str, QThread] = {}
        self._workers: dict[str, Worker] = {}

        self._chart_paths: dict[str, str] = {}

    def _build_chart_paths(self, base_path: Path) -> dict[str, str]:
        return {
            "monthlyChart": (base_path / "monthlychart.png").resolve().as_uri(),
            "dailyChart": (base_path / "dailychart.png").resolve().as_uri(),
            "incomeVsExpense": (base_path / "income_vs_expense.png").resolve().as_uri(),
            "expenseDistribution": (base_path / "expense_distribution.png").resolve().as_uri(),
        }

    def get_chart_paths(self) -> dict[str, str]:
        """Get chart paths."""
        if not self._chart_paths:
            base_path = save.data_folder_path() / "graphs"
            self._chart_paths = self._build_chart_paths(base_path)
        return self._chart_paths

    chart_paths = Property(dict, get_chart_paths)  # type: ignore  # noqa: PGH003

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

    @Slot(str, str)
    def plot_daily_transactions(self, year: str, month: str) -> None:
        """Generate daily transaction graph."""
        graph_gen.plot_daily_transactions(int(year), int(month))

    @Slot(str)
    def plot_monthly_trend(self, year: str) -> None:
        """Generate monthly trend graph."""
        graph_gen.plot_monthly_trend(int(year))

    @Slot(str)
    def plot_income_vs_expense(self, year: str) -> None:
        """Generate income vs expense graph."""
        graph_gen.plot_income_vs_expense(int(year))

    @Slot(str)
    def plot_expense_distribution(self, year: str) -> None:
        """Generate expense distribution graph."""
        graph_gen.plot_expense_distribution(int(year))

    @Slot()
    def export_database(self) -> None:
        """Export database to excel."""
        excel_gen.export_database()

    @Slot(str, str)
    def export_transactions_by_month(self, month: str, year: str) -> None:
        """Export transaction to excel."""
        excel_gen.export_transactions_by_month(int(month), int(year))

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
        graph_gen.close_graphs()
        db.close_db()
