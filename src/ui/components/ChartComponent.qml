pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string title: ""
    property color foregroundColor: "black"
    property var comboModels: []
    signal generateRequested
    property string imageSource: ""
    property var defaultIndices: []
    property var selectedIndices: defaultIndices.slice()
    property bool populateYearModel: false
    property bool includeMonths: false

    Component.onCompleted: {
        updatePlaceholderVisibility();
        if (populateYearModel) {
            let currentYear = new Date().getFullYear();
            let years = [];
            for (let i = currentYear - 25; i <= currentYear + 1; i++) {
                years.push(i.toString());
            }

            let months = [];
            if (includeMonths) {
                for (let m = 1; m <= 12; m++) {
                    months.push(m < 10 ? "0" + m : "" + m);
                }
            }

            comboModels = includeMonths ? [years, months] : [years];
            let currentMonthIndex = new Date().getMonth();
            defaultIndices = includeMonths ? [years.length - 2, currentMonthIndex] : [years.length - 2];
            selectedIndices = defaultIndices.slice();
        }
    }

    spacing: 10
    Layout.alignment: Qt.AlignLeft

    Text {
        text: root.title
        font.bold: true
        font.pointSize: 14
        color: root.foregroundColor
        Layout.alignment: Qt.AlignHCenter
    }

    Rectangle {
        Layout.preferredWidth: 600
        Layout.preferredHeight: 40
        color: "transparent"

        RowLayout {
            spacing: 10
            anchors.fill: parent

            Repeater {
                model: root.comboModels.length
                ComboBox {
                    id: comboBox
                    required property int index
                    Layout.fillWidth: true
                    model: root.comboModels[index]
                    Layout.preferredHeight: 40
                    popup.height: 300

                    currentIndex: root.selectedIndices.length > index ? root.selectedIndices[index] : 0

                    onCurrentIndexChanged: {
                        root.selectedIndices[index] = currentIndex;
                    }
                }
            }

            Button {
                text: "Generate Graph"
                onClicked: {
                    root.generateRequested();
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
            id: chartImage
            anchors.centerIn: parent
            width: parent.width
            height: parent.height

            onStatusChanged: {
                if (status === Image.Error) {
                    placeholderText.visible = true;
                    chartImage.visible = false;
                } else if (status === Image.Ready) {
                    placeholderText.visible = false;
                    chartImage.visible = true;
                }
            }
        }

        Text {
            id: placeholderText
            anchors.centerIn: parent
            text: "No graph available yet.\nClick 'Generate Graph' to create one."
            color: "#666"
            font.pixelSize: 18
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            visible: false
        }
    }
    function reloadImage() {
        var base = imageSource.split("?")[0];
        var timestamp = new Date().getTime();  // unique value to force reload
        chartImage.source = base + "?" + timestamp;
    }
    function updatePlaceholderVisibility() {
        if (!root.imageSource) {
            placeholderText.visible = true;
            chartImage.visible = false;
        } else {
            placeholderText.visible = false;
            chartImage.visible = true;
        }
    }
}
