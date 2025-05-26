import QtQuick
import QtQuick.Controls.Material

Button {
    id: textIconButton
    property alias textIcon: buttonText.text
    property alias iconPixelSize: buttonText.font.pixelSize
    property string toolTipText: ""
    property alias iconColor: buttonText.color
    property color hoverColor: "white"
    property real hoverOpacity: 0.25

    height: 40

    ToolTip {
        id: toolTip
        visible: textIconButton.hovered && textIconButton.toolTipText !== ""
        text: textIconButton.toolTipText
        delay: 500
        timeout: 5000
    }

    contentItem: Item {
        anchors.fill: parent
        anchors.centerIn: parent
        Text {
            id: buttonText
            anchors.centerIn: parent
            width: 18
            height: 18
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        id: buttonBackground
        anchors.fill: parent
        color: textIconButton.hoverColor
        opacity: textIconButton.hovered ? textIconButton.hoverOpacity : 0
        border.width: 0
        radius: 0

        Behavior on opacity {
            NumberAnimation {
                duration: 100
            }
        }
    }
}
