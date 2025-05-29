import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtQuick.Window

Rectangle {
    id: titleBar

    property Window parentWindow: null
    property string title: "Window Title"
    property int borderSize: 0
    property bool showMinimizeButton: true
    property bool showMaximizeButton: true
    property bool showCloseButton: true
    property url iconSource: ""
    property int windowControlIconSize: 20
    default property list<QtObject> extraWindowControls

    // Main component properties
    width: parent.width
    height: 40

    function toggleMaximized() {
        if (titleBar.parentWindow.visibility === Window.FullScreen) {
            titleBar.parentWindow.showNormal();
        } else {
            titleBar.parentWindow.showFullScreen();
        }
    }

    // Title bar border
    Rectangle {
        id: titleBarBorder
        color: Material.secondaryTextColor
        visible: titleBar.borderSize > 0
        height: titleBar.borderSize
        width: parent.width
        anchors.bottom: parent.bottom
        z: 10
    }

    // Gradient background
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        GradientBackground {
            gradientColor: Material.primary
        }
    }

    Item {
        anchors.fill: parent

        // Handle bar double click to toggle maximize/minimize
        TapHandler {
            onTapped: if (tapCount === 2 && titleBar.showMaximizeButton) {
                titleBar.toggleMaximized();
            }
            gesturePolicy: TapHandler.DragThreshold
        }

        // Handle window dragging
        DragHandler {
            grabPermissions: TapHandler.CanTakeOverFromAnything
            onActiveChanged: if (active) {
                if (titleBar.parentWindow.visibility === Window.FullScreen) {
                    // Trying to drag from fullscreen:

                    // Get original dimensions before normalization
                    const screenWidth = titleBar.parentWindow.width;
                    const screenHeight = titleBar.parentWindow.height;

                    // Get the mouse position relative to the screen
                    const mousePos = titleBar.mapToGlobal(Qt.point(centroid.position.x, centroid.position.y));

                    // Normalize window
                    titleBar.parentWindow.showNormal();

                    // Resize window
                    titleBar.parentWindow.width = screenWidth * 0.8;
                    titleBar.parentWindow.height = screenHeight * 0.8;

                    // Calculate new positions
                    const newX = mousePos.x - (titleBar.parentWindow.width / 2);
                    const newY = mousePos.y - (titleBar.height / 2);

                    // Calculate limits
                    const XLimit = screenWidth - titleBar.parentWindow.width;
                    const YLimit = screenHeight - titleBar.parentWindow.height;

                    // Apply new position with limits
                    titleBar.parentWindow.x = Math.max(0, Math.min(XLimit, newX));
                    titleBar.parentWindow.y = Math.max(0, Math.min(YLimit, newY));
                }

                titleBar.parentWindow.startSystemMove();
            }
        }
    }

    // Title bar elements
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 0
        spacing: 10

        // App Logo/Icon
        Rectangle {
            id: appIcon
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            color: "transparent"
            visible: titleBar.iconSource != ""
            Layout.alignment: Qt.AlignCenter

            Image {
                anchors.fill: parent
                source: titleBar.iconSource
                visible: titleBar.iconSource != ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
        }

        // Title text
        Text {
            text: titleBar.title
            color: "white"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            opacity: 0.9
            Layout.alignment: Qt.AlignCenter
            Layout.leftMargin: 10
            Layout.fillWidth: true // Creates a gap between the window controls
        }

        // Window controls
        Row {
            spacing: 0
            Layout.alignment: Qt.AlignCenter

            // Custom window controls
            Repeater {
                model: titleBar.extraWindowControls
                delegate: Item {
                    required property var modelData
                    implicitWidth: modelData.width
                    implicitHeight: modelData.height
                    Component.onCompleted: {
                        modelData.parent = this;
                    }
                }
            }

            // Minimize button
            TBarTextIconButton {
                height: 40
                textIcon: "–"
                toolTipText: qsTr("Minimize")
                iconPixelSize: titleBar.windowControlIconSize
                iconColor: "white"
                visible: titleBar.showMinimizeButton
                onClicked: titleBar.parentWindow.showMinimized()
            }

            // Maximize button
            TBarTextIconButton {
                height: 40
                textIcon: titleBar.parentWindow.visibility === Window.FullScreen ? "❐" : "□"
                toolTipText: qsTr("Maximize")
                iconPixelSize: titleBar.windowControlIconSize
                iconColor: "white"
                visible: titleBar.showMaximizeButton
                onClicked: titleBar.toggleMaximized()
            }

            // Close button
            TBarTextIconButton {
                height: 40
                textIcon: "×"
                toolTipText: qsTr("Close")
                iconPixelSize: titleBar.windowControlIconSize
                iconColor: "white"
                hoverColor: "red"
                hoverOpacity: 0.8
                visible: titleBar.showCloseButton
                onClicked: titleBar.parentWindow.close()
            }
        }
    }
}
