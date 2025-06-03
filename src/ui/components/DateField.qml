import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: dateFieldContainer

    property int yearCap: new Date().getFullYear()

    property alias badInputText: badInputText.text
    property alias badInputTextVisible: badInputText.visible
    property alias month: monthField.currentIndex
    property alias day: dayField.text
    property alias year: yearField.text

    function clear() {
        monthField.currentIndex = 0;
        dayField.clear();
        yearField.clear();
        badInputTextVisible = false;
    }

    ColumnLayout {
        anchors.fill: parent

        // Date field
        RowLayout {
            Layout.fillWidth: true

            // Month field
            ComboBox {
                id: monthField

                model: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
                currentIndex: new Date().getMonth()
            }

            // Day field
            TextField {
                id: dayField

                placeholderText: qsTr("Day")
                validator: IntValidator {
                    bottom: 1
                    top: 31
                }
            }

            // Year field
            TextField {
                id: yearField

                placeholderText: qsTr("Year")
                validator: IntValidator {
                    bottom: 1925
                    top: dateFieldContainer.yearCap
                }
            }
        }

        // Bad input text
        Text {
            id: badInputText

            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
            Layout.fillWidth: true

            visible: false
            color: "#D32F2F"
        }
    }
}
