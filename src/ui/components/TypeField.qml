import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: typeFieldContainer

    property string type: typeField.currentText.toLocaleLowerCase()
    property alias currentIndex: typeField.currentIndex

    signal selectionChanged(string type)

    function setState(transaction_type) {
        if (transaction_type == "expense") {
            typeField.currentIndex = 0;
        } else if (transaction_type == "income") {
            typeField.currentIndex = 1;
        } else {
            console.error("Cannot set TypeField state, because the transaction type is invalid");
        }

        if (typeField.currentIndex !== typeField.lastIndex) {
            typeField.lastIndex = typeField.currentIndex;
            typeFieldContainer.selectionChanged(typeField.model[typeField.currentIndex].toLocaleLowerCase());
        }
    }

    ComboBox {
        id: typeField
        model: ["Expense", "Income"]

        property int lastIndex: 0

        onActivated: function (index) {
            if (index !== lastIndex) {
                lastIndex = index;
                typeFieldContainer.selectionChanged(typeField.model[index].toLocaleLowerCase());
            }
        }
    }
}
