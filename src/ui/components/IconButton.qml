import QtQuick
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects
import QtQuick.Controls

Button {
    id: button

    property color hoverColor: Material.accentColor
    property color iconColor: Material.dividerColor
    property alias source: icon.source
    property alias toolTipText: toolTip.text
    property alias iconHeight: icon.height
    property alias iconWidth: icon.width

    background: null

    contentItem: Item {
        anchors.fill: parent

        Image {
            id: icon

            anchors.centerIn: parent
            width: 20
            height: 20
            mipmap: true
            smooth: true
            visible: false
        }

        ColorOverlay {
            id: iconOverlay

            anchors.fill: icon
            source: icon
            color: button.hovered ? button.hoverColor : button.iconColor

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }

        ToolTip {
            id: toolTip

            visible: button.hovered
            delay: 500
            timeout: 5000
        }
    }
}
