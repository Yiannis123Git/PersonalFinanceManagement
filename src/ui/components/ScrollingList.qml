pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects

Rectangle {
    id: scrollingList

    property alias model: listView.model
    property alias delegate: listView.delegate
    property real gradientOpacity: 1
    property string headerText: ""
    property real fontScaleFactor: 0.04  // 4% of height by default
    property real headerHeightFactor: 0.06  // 12% of container height by default
    property real minimumFontSize: 12
    property real maximumFontSize: 30

    signal createButtonClicked

    function responsiveFontSize() {
        // Scale based on component height
        const calculatedSize = Math.max(minimumFontSize, Math.min(maximumFontSize, height * fontScaleFactor));
        return calculatedSize;
    }

    border.width: 1
    border.color: Material.dividerColor

    // Use gradient background
    color: "Transparent"
    GradientBackground {
        opacity: parent.gradientOpacity
    }

    // Shadow effect
    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        horizontalOffset: -2
        verticalOffset: 2
        radius: 8.0
        samples: 17
        color: "#30000000"
    }

    ListView {
        id: listView
        anchors.fill: parent

        ScrollBar.vertical: ScrollBar {}

        header: Rectangle {
            color: "transparent"
            width: parent.width
            height: scrollingList.headerText ? scrollingList.height * scrollingList.headerHeightFactor : 0
            Text {
                text: scrollingList.headerText
                color: Material.foreground
                font.weight: Font.StyleItalic
                font.pointSize: scrollingList.responsiveFontSize()
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.centerIn: parent

                // Text shadow effect
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    horizontalOffset: -2
                    verticalOffset: 2
                    radius: 8.0
                    samples: 17
                    color: "#30000000"
                }
            }
        }

        // Add extra space at the bottom avoid creation button overlap
        footer: Item {
            width: parent.width
            height: scrollingList.height * 0.15
        }
    }

    // Entry creation button
    ToolButton {
        id: roundButton
        text: qsTr("+")
        highlighted: true
        Material.elevation: 6
        width: Math.min(parent.width * 0.0625, Screen.width * 0.055)
        height: width
        anchors.margins: 10
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        font.pixelSize: width * 0.4

        background: Rectangle {
            color: Material.accent
            radius: roundButton.width / 2
            border.color: Material.dividerColor
            border.width: 1

            // Button shadow
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: -2
                verticalOffset: 2
                radius: 8.0
                samples: 17
                color: "#30000000"
            }
        }

        contentItem: Text {
            text: roundButton.text
            font: roundButton.font
            color: Material.foreground
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: {
            scrollingList.createButtonClicked();
        }
    }
}
