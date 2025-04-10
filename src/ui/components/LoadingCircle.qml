import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects

Item {
    id: loadingContainer
    property string statusText: ""
    property color textColor: Material.foreground
    property color circleColor: Material.accentColor

    implicitHeight: 100
    implicitWidth: 100

    property int _ellipsisState: 0

    function getEllipsis() {
        switch (_ellipsisState) {
        case 0:
            return "";
        case 1:
            return ".";
        case 2:
            return "..";
        case 3:
            return "...";
        default:
            return "";
        }
    }

    Timer {
        id: ellipsisTimer
        interval: 1000
        running: loadingContainer.statusText !== ""
        repeat: true
        onTriggered: {
            loadingContainer._ellipsisState = (loadingContainer._ellipsisState + 1) % 4;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Item {
            Layout.alignment: Qt.AlignHCenter
            property real size: Math.min(loadingContainer.width, loadingContainer.height) // ensure 1:1 aspect ratio
            Layout.preferredWidth: size
            Layout.preferredHeight: size

            Image {
                id: loadingCircle
                source: "qrc:/ui/assets/images/loading-circle.png"
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                visible: false
            }

            ColorOverlay {
                id: loadingCircleOverlay
                anchors.fill: parent
                source: loadingCircle
                color: loadingContainer.circleColor

                RotationAnimation {
                    target: loadingCircleOverlay
                    running: loadingCircle.status === Image.Ready
                    from: 0
                    to: 360
                    duration: 2000
                    loops: Animation.Infinite
                }
            }
        }

        Text {
            visible: loadingContainer.statusText !== ""
            text: loadingContainer.statusText + loadingContainer.getEllipsis()
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            color: loadingContainer.textColor
            wrapMode: Text.WordWrap
            font.pointSize: Math.max(10, Math.min(loadingContainer.width, loadingContainer.height) * 0.08)
        }
    }
}
