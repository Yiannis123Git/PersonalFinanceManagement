// Disable certain linting rules for this file due to AppController usage
// qmllint disable unqualified
// qmllint disable import

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import "./components"
import AppController 1.0

ApplicationWindow {
    id: appWindow
    width: Screen.width / 2
    height: Screen.height / 2
    visible: true
    title: qsTr("Personal Finance Management")

    // Window size constraints
    minimumWidth: 800
    minimumHeight: 600
    maximumWidth: Screen.width
    maximumHeight: Screen.height

    // Remove window title bar
    flags: Qt.Window | Qt.FramelessWindowHint

    // Set app material
    Material.theme: Themes.current.theme
    Material.accent: Themes.current.accent
    Material.primary: Themes.current.primary
    Material.elevation: Themes.current.elevation

    // Add window resize functionality

    WindowResizer {
        id: appWindowResizer
        targetWindow: appWindow
        borderWidth: 5
    }

    // App window controls
    menuBar: Column {
        width: parent.width

        // Window app custom title bar
        TitleBar {
            id: appWindowTitleBar
            parentWindow: appWindow
            title: qsTr("Personal Finance Management")
            iconSource: "qrc:/ui/assets/images/app-icon.png"
            showMinimizeButton: true
            showMaximizeButton: true
            showCloseButton: true

            // Theme toggle
            Button {
                id: appThemeToggle
                width: 20
                height: 20

                ToolTip {
                    visible: appThemeToggle.hovered
                    text: Themes.currentTheme === "Dark" ? qsTr("Switch to Light Theme") : qsTr("Switch to Dark Theme")
                    delay: 500
                    timeout: 5000
                }

                contentItem: Item {
                    anchors.fill: parent
                    Image {
                        id: themeIcon
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: Themes.currentTheme === "Dark" ? "qrc:/ui/assets/images/light-theme-icon.png" : "qrc:/ui/assets/images/dark-theme-icon.png"
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: themeIcon
                        source: themeIcon
                        color: appThemeToggle.hovered ? Material.accentColor : Material.foreground
                    }
                }

                background: Rectangle {
                    anchors.fill: parent
                    opacity: 0
                }

                onClicked: function () {
                    if (Themes.currentTheme === "Dark") {
                        Themes.setTheme("Light");
                    } else {
                        Themes.setTheme("Dark");
                    }
                }
            }
        }
    }

    // Loading screen
    Loader {
        active: !AppController.init_status
        anchors.centerIn: parent
        width: parent.width * 0.3
        height: parent.height * 0.3
        sourceComponent: LoadingCircle {
            statusText: qsTr(AppController.current_init_step)
        }
    }

    // App window content
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Tab bar
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            contentHeight: parent.height * 0.08

            TabButton {
                text: qsTr("Overview")
                font.pointSize: Math.max(10, Math.min(parent.width, parent.height) * 0.15)
                onClicked: stackView.currentIndex = 0
            }

            TabButton {
                text: qsTr("Data Analysis")
                font.pointSize: Math.max(10, Math.min(parent.width, parent.height) * 0.15)
                onClicked: stackView.currentIndex = 1
            }
        }

        // Tab content
        StackLayout {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: overviewTab
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    text: qsTr("Overview tab content")
                    font.pointSize: Math.max(10, Math.min(parent.width, parent.height) * 0.05)
                    color: Material.foreground
                }
            }

            Item {
                id: dataAnalysisTab
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: scrollArea
                    anchors.fill: parent
                    contentWidth: chartsGrid.implicitWidth
                    contentHeight: chartsGrid.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: layoutColumn
                        width: parent.width
                        spacing: 20

                        GridLayout {
                            id: chartsGrid
                            width: scrollArea.width
                            columns: appWindow.width > 1300 ? 2 : 1  // use appWindow directly
                            rowSpacing: 20
                            columnSpacing: 20

                            // Chart 1
                            ColumnLayout {
                                spacing: 10
                                Layout.alignment: Qt.AlignHCenter
                                Text {
                                    text: "Income&Expenses for Year in Months"
                                    font.bold: true
                                    font.pointSize: 14
                                    color: Material.foreground
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Rectangle {
                                    width: 600
                                    height: 40
                                    color: "transparent"
                                    RowLayout {
                                        spacing: 10
                                        anchors.fill: parent
                                        ComboBox {
                                            id: chart1Year
                                            Layout.fillWidth: true
                                            model: ["2023", "2024", "2025"]
                                            currentIndex: 2
                                            Layout.preferredHeight: 40
                                        }
                                        Button {
                                            text: "Generate Graph"
                                            onClicked: {
                                                var selectedYear = chart1Year.currentText;
                                                AppController.plot_monthly_trend(selectedYear);
                                            }
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.preferredWidth: 600
                                    Layout.preferredHeight: 400
                                    color: "#eeeeee"
                                    border.color: "#cccccc"
                                    border.width: 1
                                    radius: 8

                                    Image {
                                        id: chartImage1
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: parent.height
                                        source: "../graphs/monthlychart.png"
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Chart Placeholder"
                                        color: "#888"
                                        visible: chartImage1.source === "graphs/monthlychart.png" && !chartImage1.visible
                                    }
                                }
                            }

                            // Chart 2
                            ColumnLayout {
                                spacing: 10
                                Layout.alignment: Qt.AlignHCenter
                                Text {
                                    text: "Income&Expenses for Month in Days"
                                    font.bold: true
                                    font.pointSize: 14
                                    color: Material.foreground
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Rectangle {
                                    width: 600
                                    height: 40
                                    color: "transparent"
                                    RowLayout {
                                        spacing: 10
                                        anchors.fill: parent
                                        ComboBox {
                                            id: chart2Year
                                            Layout.fillWidth: true
                                            model: ["2023", "2024", "2025"]
                                            currentIndex: 2
                                            Layout.preferredHeight: 40
                                        }
                                        ComboBox {
                                            id: chart2Month
                                            Layout.fillWidth: true
                                            model: ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
                                            currentIndex: 0
                                            Layout.preferredHeight: 40
                                        }
                                        Button {
                                            text: "Generate Graph"
                                            onClicked: {
                                                // Get the selected year and month
                                                var selectedYear = chart2Year.currentText;
                                                var selectedMonth = chart2Month.currentText;
                                                // Call the plot function in AppController
                                                AppController.plot_daily_transactions(selectedYear, selectedMonth);
                                            }
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.preferredWidth: 600
                                    Layout.preferredHeight: 400
                                    color: "#eeeeee"
                                    border.color: "#cccccc"
                                    border.width: 1
                                    radius: 8

                                    Image {
                                        id: chartImage2
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: parent.height
                                        source: "../graphs/dailychart.png"
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Chart Placeholder"
                                        color: "#888"
                                        visible: chartImage2.source === "graphs/dailychart.png" && !chartImage2.visible
                                    }
                                }
                            }

                            // Chart 3
                            ColumnLayout {
                                spacing: 10
                                Layout.alignment: Qt.AlignHCenter
                                Text {
                                    text: "Total Income&Expenses for Year"
                                    font.bold: true
                                    font.pointSize: 14
                                    color: Material.foreground
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Rectangle {
                                    width: 600
                                    height: 40
                                    color: "transparent"
                                    RowLayout {
                                        spacing: 10
                                        anchors.fill: parent
                                        ComboBox {
                                            id: chart3Year
                                            Layout.fillWidth: true
                                            model: ["2023", "2024", "2025"]
                                            currentIndex: 2
                                            Layout.preferredHeight: 40
                                        }
                                        Button {
                                            text: "Generate Graph"
                                            onClicked: {
                                                // Get the selected year and month
                                                var selectedYear = chart3Year.currentText;
                                                // Call the plot function in AppController
                                                AppController.plot_income_vs_expense(selectedYear);
                                            }
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.preferredWidth: 600
                                    Layout.preferredHeight: 400
                                    color: "#eeeeee"
                                    border.color: "#cccccc"
                                    border.width: 1
                                    radius: 8

                                    Image {
                                        id: chartImage3
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: parent.height
                                        source: "../graphs/income_vs_expense.png"
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Chart Placeholder"
                                        color: "#888"
                                        visible: chartImage3.source === "graphs/income_vs_expense.png" && !chartImage3.visible
                                    }
                                }
                            }

                            // Chart 4
                            ColumnLayout {
                                spacing: 10
                                Layout.alignment: Qt.AlignHCenter
                                Text {
                                    text: "Expense Distribution by Category"
                                    font.bold: true
                                    font.pointSize: 14
                                    color: Material.foreground
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Rectangle {
                                    width: 600
                                    height: 40
                                    color: "transparent"
                                    RowLayout {
                                        spacing: 10
                                        anchors.fill: parent
                                        ComboBox {
                                            id: chart4Year
                                            Layout.fillWidth: true
                                            model: ["2023", "2024", "2025"]
                                            currentIndex: 2
                                            Layout.preferredHeight: 40
                                        }
                                        Button {
                                            text: "Generate Graph"
                                            onClicked: {
                                                // Get the selected year
                                                var selectedYear = chart4Year.currentText;
                                                // Call the plot function in AppController
                                                AppController.plot_expense_distribution(selectedYear);
                                            }
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.preferredWidth: 600
                                    Layout.preferredHeight: 400
                                    color: "#eeeeee"
                                    border.color: "#cccccc"
                                    border.width: 1
                                    radius: 8

                                    Image {
                                        id: chartImage4
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: parent.height
                                        source: "../graphs/expense_distribution.png"  // Fixed path to the generated graph

                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Chart Placeholder"
                                        color: "#888"
                                        visible: chartImage4.source === "graphs/expense_distribution.png" && !chartImage4.visible
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
