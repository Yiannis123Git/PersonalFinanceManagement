import QtQuick
import QtQuick.Layouts

Item {
    id: transactionFieldsContainer

    property alias nameBadInputText: nameField.badInputText
    property alias nameBadInputTextVisible: nameField.badInputTextVisible
    property alias amountBadInputText: amountField.badInputText
    property alias amountBadInputTextVisible: amountField.badInputTextVisible
    property alias executionDateBadInputText: executionDateField.badInputText
    property alias executionDateBadInputTextVisible: executionDateField.badInputTextVisible
    property alias categoryBadInputText: categoryField.badInputText
    property alias categoryBadInputTextVisible: categoryField.badInputTextVisible

    signal categoryDeleted
    signal categoryEdited

    anchors.fill: parent

    function getFieldData() {
        return {
            name: nameField.text,
            amount: amountField.text,
            executionDate: {
                year: executionDateField.year,
                month: executionDateField.month,
                day: executionDateField.day
            },
            type: typeField.type,
            category: categoryField.category
        };
    }

    function resetFields() {
        nameField.clear();
        amountField.clear();
        executionDateField.clear();
        typeField.setState("expense");
        categoryField.clear();
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
            case "executionDate":
                executionDateField.year = fieldData[fieldName].year ?? "";
                executionDateField.month = fieldData[fieldName].month ?? 0;
                executionDateField.day = fieldData[fieldName].day ?? "";
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
        executionDateField.badInputTextVisible = false;
        categoryField.badInputTextVisible = false;
    }

    function syncCategoryField() {
        categoryField.sync();
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

        // Date field
        DateField {
            id: executionDateField
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
            onCategoryDeleted: {
                transactionFieldsContainer.categoryDeleted();
            }
            onCategoryEdited: {
                transactionFieldsContainer.categoryEdited();
            }
        }
    }
}
