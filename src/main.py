import argparse
import sys

from PySide6.QtCore import QTimer
from PySide6.QtGui import QIcon
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterSingletonInstance
from PySide6.QtWidgets import QApplication

# Import app modules
from app_controller import AppController

# Import qml data models
from py_qml import category_model, monthly_transaction_model, transaction_model  # noqa: F401

# Import qrc resources
from ui import qml_rc  # noqa: F401


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--temp-instance",
        type=bool,
        help="Creates a temp app instance. Data will not be saved.",
        default=False,
    )

    return parser.parse_args()


if __name__ == "__main__":
    # Get command line arguments
    cl_args = parse_args()

    # Create the application controller
    app_controller = AppController()

    # Register the application controller on the qml side
    qmlRegisterSingletonInstance(
        AppController,
        "AppController",
        1,
        0,
        "AppController",  # type: ignore  # noqa: PGH003
        app_controller,
    )

    app = QApplication(sys.argv)
    QApplication.setOrganizationName("HLE43-3")
    QApplication.setApplicationName("Personal Finance Management")

    # set application icon
    app.setWindowIcon(QIcon(":/ui/assets/images/app-icon.png"))

    # Create qml engine
    engine = QQmlApplicationEngine()

    # Add the current directory to the import paths and load the main module.
    engine.addImportPath(sys.path[0])
    engine.loadFromModule("ui", "Main")

    # Check if the QML file was loaded successfully
    if not engine.rootObjects():
        sys.exit(-1)

    # Start initialization process
    QTimer.singleShot(0, lambda: app_controller.start_initialization(cl_args))

    # Start event loop (yields)
    exit_code = app.exec()

    # Cleanup and exit
    del engine
    app_controller.cleanup()
    sys.exit(exit_code)
