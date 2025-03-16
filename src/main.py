import sys

from PySide6.QtWidgets import (
    QApplication,
    QHBoxLayout,
    QLabel,
    QPushButton,
    QStackedWidget,
    QVBoxLayout,
    QWidget,
)


class MainWindow(QWidget):
    def __init__(self) -> None:
        super().__init__()
        self.init_ui()

    def init_ui(self) -> None:
        """Initialize the main window layout and widgets."""
        layout = QVBoxLayout()

        # Button Container for main view buttons
        button_layout = QHBoxLayout()
        self.btn_income = QPushButton("Income")
        self.btn_expenses = QPushButton("Expenses")
        self.btn_dataAnalysis = QPushButton("Data Analysis")

        # Make them Checkable so we can then visually show which button is pressed
        self.btn_income.setCheckable(True)
        self.btn_expenses.setCheckable(True)
        self.btn_dataAnalysis.setCheckable(True)

        button_layout.addWidget(self.btn_income)
        button_layout.addWidget(self.btn_expenses)
        button_layout.addWidget(self.btn_dataAnalysis)

        layout.addLayout(button_layout)

        # Stacked widget for the different views we will have
        self.stacked_widget = QStackedWidget()

        self.incomeView = QLabel("This is the Income View", self)
        self.expenseView = QLabel("This is the Expenses View", self)
        self.dataAnalysisView = QLabel("This is the Data Analysis view", self)

        self.stacked_widget.addWidget(self.incomeView)
        self.stacked_widget.addWidget(self.expenseView)
        self.stacked_widget.addWidget(self.dataAnalysisView)

        layout.addWidget(self.stacked_widget)

        self.btn_income.clicked.connect(lambda: self.switch_view(0, self.btn_income))
        self.btn_expenses.clicked.connect(
            lambda: self.switch_view(1, self.btn_expenses),
        )
        self.btn_dataAnalysis.clicked.connect(
            lambda: self.switch_view(2, self.btn_dataAnalysis),
        )

        self.setLayout(layout)
        self.setWindowTitle("Personal Finance Management")
        self.resize(400, 300)

        self.setFocus()

    def switch_view(self, index: int, button: QPushButton) -> None:
        """Set stacked widget current index and update button styles."""
        self.stacked_widget.setCurrentIndex(index)
        self.update_button_styles(button)

    def update_button_styles(self, selected_button: QPushButton) -> None:
        """Visually represent active button and current view."""
        buttons = [self.btn_income, self.btn_expenses, self.btn_dataAnalysis]
        for button in buttons:
            if button == selected_button:
                button.setStyleSheet("background-color: lightblue; font-weight: bold;")
                button.setChecked(True)
            else:
                button.setStyleSheet("")
                button.setChecked(False)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
