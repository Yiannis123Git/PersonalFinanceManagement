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
                RowLayout {
                    anchors.fill: parent
                    spacing: 20
                    ChartLayout {
                        appController: AppController
                        appWindow: appWindow
                    }
                    ExportComponent {
                        appController: AppController
                    }
                }
            }
        }
    }
}
