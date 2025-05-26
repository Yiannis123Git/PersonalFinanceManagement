import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects

Button {
    id: button
    height: 40

    property alias imageSource: buttonImage.source
    property alias imageColor: colorOverlay.color
    property alias toolTipText: toolTip.text

    ToolTip {
        id: toolTip
        visible: button.hovered
        delay: 500
        timeout: 5000
    }

    contentItem: Item {
        anchors.fill: parent

        Image {
            id: buttonImage
            anchors.centerIn: parent
            width: 18
            height: 18
            visible: false
        }

        ColorOverlay {
            id: colorOverlay
            anchors.fill: buttonImage
            source: buttonImage
            color: "white"
        }
    }

    background: Rectangle {
        anchors.fill: parent
        color: "white"
        opacity: button.hovered ? 0.25 : 0
        border.width: 0
        radius: 0

        Behavior on opacity {
            NumberAnimation {
                duration: 100
            }
        }
    }
}
