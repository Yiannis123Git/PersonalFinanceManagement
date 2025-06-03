// Disable certain linting rules for this file due to AppController and PFM.Models usage
// qmllint disable unqualified
// qmllint disable import
// qmllint disable missing-property

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import AppController 1.0
import PFM.Models

// Categories data model

Item {
    id: categoryFieldContainer

    property alias badInputText: badInputText.text
    property alias badInputTextVisible: badInputText.visible
    property var category: categoryField.optionSelected ? categoryField.currentText : null

    signal categoryDeleted
    signal categoryEdited

    enum DialogContext {
        Create = 0,
        Edit = 1
    }

    function setState(transaction_type, category = null) {
        if (categoryModelLoader.status !== Loader.Ready) {
            console.error("Cannot set CategoryField state, because the model not ready");
            return;
        }

        // Set display_for model property (assumes its valid, if not error will propagated to the python side)
        categoryModelLoader.item.display_for = transaction_type;

        if (category === null) {
            // reset field state and set display_for model value to transaction_type
            categoryField.currentIndex = 0;
            categoryField.optionSelected = false;
            categoryField.lastSelectedIndex = 0;
        } else {
            categoryField.currentIndex = categoryModelLoader.item.get_index(category);
            categoryField.optionSelected = true;
            categoryField.lastSelectedIndex = categoryField.currentIndex;
        }
    }

    function clear() {
        categoryField.currentIndex = 0;
        categoryField.optionSelected = false;
        categoryField.lastSelectedIndex = 0;
        categoryModelLoader.item.display_for = "expense";
        badInputText.visible = false;
    }

    function sync() {
        if (categoryModelLoader.status !== Loader.Ready) {
            console.error("Cannot sync CategoryField model, because the model is not ready");
            return;
        }

        // Sync model with database to ensure changes made on other panels are reflected
        categoryModelLoader.item.update_model();
    }

    function _showCreateDialog() {
        categoryDialog.currentDialogContext = CategoryField.DialogContext.Create;

        newCategoryNameField.badInputTextVisible = false;
        newCategoryNameField.clear();

        categoryDialog.title = qsTr("Create a new %1 category").arg(categoryModelLoader.item.display_for);
        categoryDialog.acceptButtonText = qsTr("Create");

        categoryDialog.open();
    }

    Loader { // defer data model loading until db is ready
        id: categoryModelLoader
        active: AppController.init_status
        sourceComponent: CategoryModel {}
        asynchronous: true
    }

    // Create/Edit category dialog
    DialogBase {
        id: categoryDialog

        property int currentDialogContext: CategoryField.DialogContext.Create
        property string currentlySelectedCategory: ""

        rejectButtonText: qsTr("Cancel")

        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2

        contentItem: StringField {
            id: newCategoryNameField

            placeholderText: qsTr("New category name")
            validator: RegularExpressionValidator {
                regularExpression: /^[a-zA-Z ]{0,20}$/
            }
        }

        onAcceptButtonClicked: {
            if (categoryModelLoader.status !== Loader.Ready) {
                // Model has not loaded yet cannot call append:
                console.error("Cannot create/edit category, because the model is not ready");

                newCategoryNameField.badInputText = qsTr("An error occured, please try again");
                newCategoryNameField.badInputTextVisible = true;
                return;
            }
            let result;

            if (currentDialogContext == CategoryField.DialogContext.Create) {
                result = categoryModelLoader.item.append(newCategoryNameField.text);
            }

            if (currentDialogContext == CategoryField.DialogContext.Edit) {
                result = categoryModelLoader.item.edit(categoryDialog.currentlySelectedCategory, newCategoryNameField.text);
            }

            if (result.success === true) {
                categoryDialog.close();
                newCategoryNameField.badInputTextVisible = false;

                if (currentDialogContext == CategoryField.DialogContext.Create) {
                    // retain currently selected index
                    categoryField.currentIndex = categoryField.lastSelectedIndex + 1;
                    categoryField.lastSelectedIndex = categoryField.lastSelectedIndex + 1;
                }

                if (currentDialogContext == CategoryField.DialogContext.Edit) {
                    // emit signal to notify that category was edited
                    categoryFieldContainer.categoryEdited();
                }
            } else {
                newCategoryNameField.badInputText = result.error;
                newCategoryNameField.badInputTextVisible = true;
            }
        }
    }

    // Delete category dialog
    DialogBase {
        id: deleteCategoryDialog

        acceptButtonText: qsTr("Delete")
        rejectButtonText: qsTr("Cancel")
        x: parent.width / 2 - width / 2
        y: parent.height / 2 - height / 2

        property int deleteIndex: -1

        contentItem: Text {
            id: deleteCategoryText

            text: qsTr("Are you sure you want to delete this category? All associated transactions will be deleted as well.")
            wrapMode: Text.WordWrap
            color: "crimson"
        }

        onAcceptButtonClicked: {
            let result = categoryModelLoader.item.remove(deleteIndex);

            if (result == true) {
                categoryFieldContainer.categoryDeleted();
                deleteCategoryDialog.close();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent

        // Category field
        ComboBox {
            id: categoryField

            property bool optionSelected: false
            property int lastSelectedIndex: 0

            Layout.preferredWidth: 250

            model: categoryModelLoader.status == Loader.Ready ? categoryModelLoader.item : []
            currentIndex: -1
            displayText: {
                if (categoryModelLoader.status == Loader.Ready) {
                    return (categoryField.optionSelected === false) ? qsTr("Select an %1 category").arg(categoryModelLoader.item.display_for) : currentText;
                }

                return "";
            }

            delegate: ItemDelegate {
                id: delegate

                width: categoryField.width
                contentItem: RowLayout {
                    // Category name
                    Text {
                        text: name
                        color: (categoryField.currentIndex !== index || categoryField.optionSelected === false) ? Material.foreground : Material.accentColor
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight | Qt.AlignBaseline

                        // Edit button
                        IconButton {
                            visible: index !== categoryField.count - 1
                            source: "qrc:/ui/assets/images/cog-icon.svg"
                            iconColor: Material.foreground
                            toolTipText: qsTr("Edit %1 %2 category").arg(name.toLowerCase()).arg(categoryModelLoader.item.display_for)

                            onClicked: {
                                categoryDialog.currentDialogContext = CategoryField.DialogContext.Edit;

                                newCategoryNameField.badInputTextVisible = false;
                                newCategoryNameField.clear();

                                newCategoryNameField.text = name;

                                categoryDialog.currentlySelectedCategory = name;

                                categoryDialog.title = qsTr("Edit %1 category: '%2'").arg(categoryModelLoader.item.display_for).arg(name);
                                categoryDialog.acceptButtonText = qsTr("Edit");

                                categoryDialog.open();
                            }
                        }

                        // Delete button
                        IconButton {
                            visible: index !== categoryField.count - 1
                            source: "qrc:/ui/assets/images/bin-icon.svg"
                            hoverColor: "red"
                            iconColor: Material.foreground
                            toolTipText: qsTr("Delete %1 %2 category").arg(name.toLowerCase()).arg(categoryModelLoader.item.display_for)

                            onClicked: {
                                deleteCategoryDialog.deleteIndex = index;
                                deleteCategoryDialog.open();
                                deleteCategoryDialog.title = qsTr("Delete %1 %2 category?").arg(name.toLowerCase()).arg(categoryModelLoader.item.display_for);
                            }
                        }
                    }

                    // Create new category button (only visible on the last element aka creation element)
                    IconButton {
                        Layout.alignment: Qt.AlignRight | Qt.AlignBaseline

                        visible: index === categoryField.count - 1
                        source: "qrc:/ui/assets/images/plus-icon.svg"
                        hoverColor: "green"
                        iconColor: Material.foreground
                        toolTipText: qsTr("Create new %1 category").arg(categoryModelLoader.item.display_for)
                        onClicked: {
                            categoryField.popup.close(); // match button behavior for consistency
                            categoryFieldContainer._showCreateDialog();
                        }
                    }
                }

                onClicked: {
                    if (index === categoryField.count - 1) {
                        categoryFieldContainer._showCreateDialog();
                    }
                }
            }

            onActivated: function (index) {
                if (index !== categoryField.count - 1) {
                    categoryField.optionSelected = true;
                    categoryField.lastSelectedIndex = index;
                } else if (categoryField.count > 1) {
                    // Revert the selection if possible
                    // This makes it so user selection is not changed when creating new categories
                    categoryField.currentIndex = categoryField.lastSelectedIndex;
                } else {
                    // No categories to select:
                    categoryField.optionSelected = false; // this exists to handle the edge cases
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
