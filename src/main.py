import sys

from PySide6.QtGui import QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication

# Import qrc resources
from ui import qml_rc  # noqa: F401

if __name__ == "__main__":
    app = QApplication(sys.argv)
    QApplication.setOrganizationName("HLE43-3")
    QApplication.setApplicationName("Personal Finance Management")

    # set application icon
    app.setWindowIcon(QIcon(":/ui/assets/images/app-icon.png"))

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
