import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material

Item {
    id: monthlyTransactionFieldsContainer

    property alias nameBadInputText: nameField.badInputText
    property alias nameBadInputTextVisible: nameField.badInputTextVisible
    property alias amountBadInputText: amountField.badInputText
    property alias amountBadInputTextVisible: amountField.badInputTextVisible
    property alias categoryBadInputText: categoryField.badInputText
    property alias categoryBadInputTextVisible: categoryField.badInputTextVisible
    property alias dayOfMonthBadInputText: dayOfMonthField.badInputText
    property alias dayOfMonthBadInputTextVisible: dayOfMonthField.badInputTextVisible
    property alias startDateBadInputText: startDateField.badInputText
    property alias startDateBadInputTextVisible: startDateField.badInputTextVisible
    property alias endDateBadInputText: endDateField.badInputText
    property alias endDateBadInputTextVisible: endDateField.badInputTextVisible

    property bool editMode: false

    signal categoryDeleted
    signal categoryEdited

    anchors.fill: parent

    function getFieldData() {
        return {
            name: nameField.text,
            amount: amountField.text,
            startDate: {
                year: startDateField.year,
                month: startDateField.month,
                day: startDateField.day
            },
            endDate: noEndDateCheckBox.checked ? null : {
                year: endDateField.year,
                month: endDateField.month,
                day: endDateField.day
            },
            dayOfMonth: dayOfMonthField.text,
            type: typeField.type,
            category: categoryField.category
        };
    }

    function resetFields() {
        nameField.clear();
        amountField.clear();
        dayOfMonthField.clear();
        startDateField.clear();
        endDateField.clear();
        typeField.setState("expense");
        categoryField.clear();
        noEndDateCheckBox.checked = false;
    }

    function setFields(fieldData) {
        for (let fieldName in fieldData) {
            let field;

            switch (fieldName) {
            case "name":
                nameField.text = fieldData[fieldName];
                break;
            case "amount":
                amountField.text = fieldData[fieldName];
                break;
            case "startDate":
                startDateField.year = fieldData[fieldName].year ?? "";
                startDateField.month = fieldData[fieldName].month ?? 0;
                startDateField.day = fieldData[fieldName].day ?? "";
                break;
            case "endDate":
                if (!fieldData[fieldName]) {
                    noEndDateCheckBox.checked = true;
                    endDateField.clear();
                } else {
                    noEndDateCheckBox.checked = false;
                    endDateField.year = fieldData[fieldName].year ?? "";
                    endDateField.month = fieldData[fieldName].month ?? 0;
                    endDateField.day = fieldData[fieldName].day ?? "";
                }
                break;
            case "dayOfMonth":
                dayOfMonthField.text = fieldData[fieldName];
                break;
            case "type":
                typeField.setState(fieldData[fieldName]);
                break;
            case "category":
                break;
            default:
                console.error("Cannot set value for unknown field:", fieldName);
                continue;
            }
        }

        // Always do category last since it depends on the type field
        if (fieldData.category) {
            categoryField.setState(fieldData["type"] ? fieldData["type"] : typeField.type, fieldData["category"]);
        }
    }

    function hideBadInputText() {
        nameField.badInputTextVisible = false;
        amountField.badInputTextVisible = false;
        dayOfMonthField.badInputTextVisible = false;
        startDateField.badInputTextVisible = false;
        endDateField.badInputTextVisible = false;
        categoryField.badInputTextVisible = false;
    }

    function syncCategoryField() {
        categoryField.sync();
    }

    function setEditMode(editMode) {
        monthlyTransactionFieldsContainer.editMode = editMode;
    }

    ColumnLayout {
        width: parent.width * 0.6
        height: parent.height
        anchors.centerIn: parent

        // Name field
        StringField {
            id: nameField
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline

            placeholderText: qsTr("Transaction's name")
            validator: RegularExpressionValidator {
                regularExpression: /^[a-zA-Z0-9 ]{0,30}$/
            }
        }

        // Amount field
        StringField {
            id: amountField
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline

            placeholderText: qsTr("Transaction's amount")
            validator: DoubleValidator {
                bottom: 0.01
                top: 1000000.00
                decimals: 2
            }
        }

        // Recurrence day
        StringField {
            id: dayOfMonthField

            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
            Layout.preferredWidth: 200

            visible: !monthlyTransactionFieldsContainer.editMode

            placeholderText: qsTr("Transaction day")
            validator: RegularExpressionValidator {
                regularExpression: /^[0-9]{0,2}$/
            }
        }

        // Start date field
        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline

            visible: !monthlyTransactionFieldsContainer.editMode

            ColumnLayout {
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline

                    text: qsTr("Start date")
                    color: Material.foreground
                }

                DateField {
                    id: startDateField
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
                }
            }
        }

        // End date field
        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline

            visible: !monthlyTransactionFieldsContainer.editMode

            ColumnLayout {
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline

                    text: qsTr("End date")
                    color: Material.foreground
                    opacity: noEndDateCheckBox.checked ? 0.5 : 1.0
                }

                DateField {
                    id: endDateField
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline

                    opacity: noEndDateCheckBox.checked ? 0.5 : 1.0
                }
            }
        }

        // Option for no end date
        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline

            visible: !monthlyTransactionFieldsContainer.editMode

            CheckBox {
                id: noEndDateCheckBox
                text: qsTr("No end date. (Will repeat indefinitely)")
            }
        }

        // Transaction type field (expense/income)
        TypeField {
            id: typeField
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline

            onSelectionChanged: function (transaction_type) {
                categoryField.setState(transaction_type);
            }
        }

        // Category field
        CategoryField {
            id: categoryField

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline

            onCategoryDeleted: {
                monthlyTransactionFieldsContainer.categoryDeleted();
            }
            onCategoryEdited: {
                monthlyTransactionFieldsContainer.categoryEdited();
            }
        }
    }
}
