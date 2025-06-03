pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects
import ".." as UI // Enable themes sigleton use

// VARIABLE WINDOW TITLE AND FINALIZATION TEXT, VARIADIC CONTENT, SHELL WINDOW TEMPLATE

Window {
    id: editorWindow

    property string windowTitle: ""
    property string finalazationText: ""
    property string actionText: ""
    property Component fieldComponent: null
    property int initialWidth: 800
    property int initialHeight: 650

    signal concluded(var fieldData)

    // Function to validate field data
    // should return true else a dict user error messages matching the field data names
    // ex: {date: "year must no exceed 2030", name: "Name cannot be blank"}
    property var validator: function (fieldData) {
        return true;
    }

    function resetFields() {
        if (fieldLoader.status !== Loader.Ready) {
            console.error("Cannot reset fields, because the fields component is not loaded yet.");
            return;
        }

        fieldLoader.item.resetFields(); // qmllint disable use-proper-function missing-property
    }

    function setFields(fieldData) {
        if (fieldLoader.status !== Loader.Ready) {
            console.error("Cannot set fields, because the fields component is not loaded yet.");
            return;
        }

        fieldLoader.item.setFields(fieldData); // qmllint disable use-proper-function missing-property
    }

    function setEditMode(editMode) {
        if (fieldLoader.status !== Loader.Ready) {
            console.error("Cannot set edit mode, because the fields component is not loaded yet.");
            return;
        }

        let setEditMode = fieldLoader.item.setEditMode; // qmllint disable use-proper-function missing-property

        if (setEditMode) {
            setEditMode(editMode); // qmllint disable use-proper-function missing-property
        } else {
            console.warn("setEditMode is not implemented in the fields component.");
        }
    }

    function syncCategoryField() {
        if (fieldLoader.status !== Loader.Ready) {
            console.error("Cannot sync category field, because the fields component is not loaded yet.");
            return;
        }

        fieldLoader.item.syncCategoryField(); // qmllint disable use-proper-function missing-property
    }

    width: 800
    height: 650

    // Window size constraints
    minimumWidth: 500
    minimumHeight: 600
    maximumWidth: 1000
    maximumHeight: 800

    flags: Qt.Window | Qt.FramelessWindowHint

    modality: Qt.ApplicationModal

    Material.theme: UI.Themes.current.theme
    Material.accent: UI.Themes.current.accent
    Material.primary: UI.Themes.current.primary
    Material.elevation: UI.Themes.current.elevation

    onVisibleChanged: function (visible) {
        if (visible) {
            // Set initial window size (We need to defer this likely due to a QML bug?)
            Qt.callLater(function () {
                editorWindow.width = editorWindow.initialWidth;
                editorWindow.height = editorWindow.initialHeight;
            });

            // Automaticly sync category field
            if (fieldLoader.status !== Loader.Ready) {
                console.error("Cannot sync category field, because the fields component is not loaded yet.");
                return;
            }
        }
    }

    GradientBackground {}

    // Make the window resizable
    WindowResizer {
        id: appWindowResizer
        targetWindow: editorWindow
        borderWidth: 5
    }

    // Window border (This is done so there is constrast between the window and the main window)
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 2
        border.color: Material.dividerColor
        radius: 8
    }

    ColumnLayout {
        anchors.fill: parent

        // Window title bar
        TitleBar {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            title: editorWindow.windowTitle
            showMaximizeButton: false
            parentWindow: editorWindow
            borderSize: 1
        }

        // Window content
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 10

            radius: 8
            border.width: 1
            border.color: Material.dividerColor

            // Use gradient background
            color: "Transparent"
            GradientBackground {
                radius: 8
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

            // Content
            ColumnLayout {
                anchors.fill: parent

                // Content title
                Text {
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.topMargin: 25
                    Layout.leftMargin: 15

                    horizontalAlignment: Text.AlignLeft
                    text: editorWindow.actionText
                    color: Material.foreground
                    font.pixelSize: Math.max(10, Math.min(parent.width, parent.height) * 0.035)
                    font.weight: Font.StyleOblique

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

                // Property fields
                Loader {
                    id: fieldLoader

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignCenter

                    active: true
                    asynchronous: true

                    sourceComponent: editorWindow.fieldComponent
                }

                // Confirmation button
                Button {
                    Layout.alignment: Qt.AlignRight
                    Layout.margins: 10

                    text: editorWindow.finalazationText

                    onClicked: {
                        // Check if the field component is loaded
                        if (fieldLoader.status !== Loader.Ready) {
                            console.error("Cannot conclude transaction creation/edition, because the field component is not loaded yet.");
                        }

                        // Hide all bad input texts (we do this so the state is refreshed upon each evaluation)
                        fieldLoader.item.hideBadInputText(); // qmllint disable use-proper-function missing-property

                        // Check if field data is valid
                        let validationResult = editorWindow.validator(fieldLoader.item.getFieldData()); // qmllint disable use-proper-function missing-property

                        if (validationResult === true) {
                            // data is valid, emit the concluded signal with field data
                            editorWindow.close();
                            editorWindow.concluded(fieldLoader.item.getFieldData()); // qmllint disable missing-property
                        } else {
                            for (let fieldName in validationResult) {
                                fieldLoader.item[fieldName + "BadInputTextVisible"] = true;
                                fieldLoader.item[fieldName + "BadInputText"] = validationResult[fieldName];
                            }
                        }
                    }
                }
            }
        }
    }
}
