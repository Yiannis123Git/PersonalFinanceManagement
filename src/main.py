import argparse
import sys

from PySide6.QtGui import QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication

# Import qrc resources
from ui import qml_rc  # noqa: F401

# Import utility functions
from utility import save


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

    app = QApplication(sys.argv)
    QApplication.setOrganizationName("HLE43-3")
    QApplication.setApplicationName("Personal Finance Management")

    # set application icon
    app.setWindowIcon(QIcon(":/ui/assets/images/app-icon.png"))

    # Establish saved data location
    save.instantiate(cl_args.temp_instance)

    engine = QQmlApplicationEngine()

    # Add the current directory to the import paths and load the main module.
    engine.addImportPath(sys.path[0])

    engine.loadFromModule("ui", "Main")

    # Check if the QML file was loaded successfully
    if not engine.rootObjects():
        sys.exit(-1)

    # Start event loop (yields)
    exit_code = app.exec()

    # Cleanup and exit
    del engine
    sys.exit(exit_code)
