import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

ColumnLayout {
    id: root
    property var appController
    property color foregroundColor
    Layout.fillHeight: true
    Layout.preferredWidth: parent.width * 0.20
    spacing: 10
    Layout.alignment: Qt.AlignCenter

    Button {
        Layout.alignment: Qt.AlignHCenter
        text: "Export All to Excel"
        onClicked: {
            console.log("Exporting all data");
            root.appController.export_database();
        }
    }

    Text {
        text: "Export by Date"
        font.bold: true
        color: root.foregroundColor
        Layout.alignment: Qt.AlignHCenter
    }

    ComboBox {
        id: exportYear
        Layout.preferredHeight: 40
        Layout.alignment: Qt.AlignHCenter
        popup.height: 300
        model: []

        Component.onCompleted: {
            let currentYear = new Date().getFullYear();
            let years = [];
            for (let i = currentYear - 25; i <= currentYear + 1; i++) {
                years.push(i.toString());
            }
            exportYear.model = years;
            exportYear.currentIndex = years.length - 2;
        }
    }

    ComboBox {
        id: exportMonth
        Layout.alignment: Qt.AlignHCenter
        model: ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
        currentIndex: new Date().getMonth()
        Layout.preferredHeight: 40
    }

    Button {
        Layout.alignment: Qt.AlignHCenter
        text: "Export Filtered"
        onClicked: {
            console.log("Exporting filtered data for", exportMonth.currentText, exportYear.currentText);
            root.appController.export_transactions_by_month(exportMonth.currentText, exportYear.currentText);
        }
    }
}
