// Disable certain linting rules for this file due to AppController and PFM.Models usage
// qmllint disable unqualified
// qmllint disable import

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import "./components"
import AppController 1.0
import PFM.Models

ApplicationWindow {
    id: appWindow
    width: Screen.width / 1.25
    height: Screen.height / 1.25
    visible: true
    title: qsTr("Personal Finance Management")

    // Window size constraints
    minimumWidth: 1400
    minimumHeight: 800
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

    // Window app custom title bar
    menuBar: TitleBar {
        id: appWindowTitleBar
        parentWindow: appWindow
        title: qsTr("Personal Finance Management")
        iconSource: "qrc:/ui/assets/images/app-icon.png"
        showMinimizeButton: true
        showMaximizeButton: true
        showCloseButton: true
        borderSize: 1

        // Theme toggle
        TBarImageButton {
            toolTipText: Themes.currentTheme === "Dark" ? qsTr("Switch to Light Theme") : qsTr("Switch to Dark Theme")
            imageSource: Themes.currentTheme === "Dark" ? "qrc:/ui/assets/images/light-theme-icon.png" : "qrc:/ui/assets/images/dark-theme-icon.png"

            onClicked: function () {
                if (Themes.currentTheme === "Dark") {
                    Themes.setTheme("Light");
                } else {
                    Themes.setTheme("Dark");
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

    // Transaction model
    Loader {
        id: transactionModelLoader
        active: AppController.init_status // defer data model loading until db is ready
        sourceComponent: TransactionModel {}
        asynchronous: true
    }

    // Monthly Transaction model
    Loader {
        id: monthlyTransactionModelLoader
        active: AppController.init_status // defer data model loading until db is ready
        sourceComponent: MonthlyTransactionModel {}
        asynchronous: true
    }

    // App window content
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: AppController.init_status

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

            Overview {
                id: overviewTab

                Layout.fillWidth: true
                Layout.fillHeight: true

                window: appWindow
                transactionModel: transactionModelLoader.status == Loader.Ready ? transactionModelLoader.item : null
                monthlyTransactionModel: monthlyTransactionModelLoader.status == Loader.Ready ? monthlyTransactionModelLoader.item : null
            }

            Item {
                id: dataAnalysisTab
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    text: qsTr("Data Analysis tab content")
                    font.pointSize: Math.max(10, Math.min(parent.width, parent.height) * 0.05)
                    color: Material.foreground
                }
            }
        }
    }
}
