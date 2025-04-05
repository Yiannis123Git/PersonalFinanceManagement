import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtQuick.Window

// Adds a custom title bar with customizable window controls
ToolBar {
    id: titleBar

    // Customizable properties
    property Window parentWindow: null
    property string title: "Window Title"
    property int borderSize: 1
    property int heightValue: 40
    property bool showMinimizeButton: true
    property bool showMaximizeButton: true
    property bool showCloseButton: true
    property url iconSource: ""
    property int windowControlIconSize: 20
    default property list<QtObject> customWindowControls

    // main component properties
    width: parent.width
    height: heightValue

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
        color: Material.foreground
        visible: titleBar.borderSize > 0
        height: titleBar.borderSize
        width: parent.width
        anchors.bottom: parent.bottom
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
        anchors.rightMargin: 15
        spacing: 10

        // App Logo/Icon
        Rectangle {
            id: appIcon
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: 5
            color: titleBar.iconSource == "" ? Material.accentColor : "transparent"
            visible: titleBar.iconSource != ""
            Layout.alignment: Qt.AlignVCenter

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
            color: Material.foreground
            font.pixelSize: 14
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 10
            Layout.fillWidth: true
        }

        // Window controls
        Row {
            spacing: 15
            Layout.alignment: Qt.AlignVCenter

            // Custom window controls
            Repeater {
                model: titleBar.customWindowControls
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
            Text {
                id: minimizeButton
                text: "−"
                font.pixelSize: titleBar.windowControlIconSize
                color: hovered ? Material.accentColor : Material.foreground
                visible: titleBar.showMinimizeButton
                property bool hovered: false

                MouseArea {
                    id: minimizeButtonArea
                    anchors.fill: parent
                    anchors.margins: -5
                    onClicked: titleBar.parentWindow.showMinimized()
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                }
            }

            // Maximize button
            Text {
                id: maximizeButton
                text: titleBar.parentWindow.visibility === Window.FullScreen ? "❐" : "□"
                font.pixelSize: titleBar.windowControlIconSize - 2
                color: hovered ? Material.accentColor : Material.foreground
                visible: titleBar.showMaximizeButton
                property bool hovered: false

                MouseArea {
                    id: maximizeButtonArea
                    anchors.fill: parent
                    anchors.margins: -5
                    onClicked: titleBar.toggleMaximized()
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                }
            }

            // Close button
            Text {
                id: closeButton
                text: "×"
                font.pixelSize: titleBar.windowControlIconSize
                color: hovered ? "#E81123" : Material.foreground
                visible: titleBar.showCloseButton
                property bool hovered: false

                MouseArea {
                    id: closeButtonArea
                    anchors.fill: parent
                    anchors.margins: -5
                    onClicked: titleBar.parentWindow.close()
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                }
            }
        }
    }
}
