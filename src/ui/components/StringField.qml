import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    property alias placeholderText: field.placeholderText
    property alias text: field.text
    property alias validator: field.validator
    property alias badInputText: badInputText.text
    property alias badInputTextVisible: badInputText.visible

    function clear() {
        field.clear();
        badInputTextVisible = false;
    }

    ColumnLayout {
        anchors.fill: parent

        TextField {
            id: field

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        }

        Text {
            id: badInputText

            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
            Layout.fillWidth: true

            visible: false
            color: "#D32F2F"
        }
    }
}
