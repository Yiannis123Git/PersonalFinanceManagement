import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

import ".." as UI // Enable themes sigleton use

ItemDelegate {
    id: delegate

    required property var model
    required property ApplicationWindow window // we use this to avoid null errors during model deletions

    signal transactionEdit(var model)
    signal transactionDelete(var model)

    width: parent ? parent.width : 0 // Avoid null error during model deletions
    height: 100
    padding: Math.max(40, delegate.window.width * 0.04)

    contentItem: Item {
        RowLayout {
            anchors.fill: parent

            // Date
            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 1

                text: delegate.model.date.toLocaleDateString(Qt.locale(), "dd MMMM yyyy")
                color: Material.foreground
                font.weight: Font.StyleItalic
                font.pointSize: Math.max(16, Math.min(delegate.window.width, delegate.window.height) * 0.02)
            }

            // Name and Category
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1

                spacing: 5

                Text {
                    Layout.fillWidth: true

                    text: delegate.model.name
                    color: Material.foreground
                    font.bold: true
                    font.pointSize: Math.max(16, Math.min(delegate.window.width, delegate.window.height) * 0.02)
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true

                    text: delegate.model.category
                    color: Material.foreground
                    font.pointSize: Math.max(12, Math.min(delegate.window.width, delegate.window.height) * 0.015)
                    elide: Text.ElideRight
                }
            }

            // Amount
            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 1

                text: delegate.model.amount + "€"
                font.pointSize: Math.max(20, Math.min(delegate.window.width, delegate.window.height) * 0.025)
                color: delegate.model.type === "income" ? "green" : "red"
            }

            Item {
                Layout.fillWidth: true  // This item will take up the remaining space
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1

                spacing: Math.max(40, delegate.window.width * 0.04)

                // Edit button
                IconButton {
                    iconColor: Material.foreground
                    iconHeight: Math.max(40, Math.min(delegate.window.width, delegate.window.height) * 0.05)
                    iconWidth: Math.max(40, Math.min(delegate.window.width, delegate.window.height) * 0.05)
                    source: "qrc:/ui/assets/images/cog-icon.svg"
                    toolTipText: qsTr("Edit transaction")

                    onClicked: {
                        delegate.transactionEdit(delegate.model);
                    }
                }

                // Delete button
                IconButton {
                    iconColor: Material.foreground
                    iconHeight: Math.max(40, Math.min(delegate.window.width, delegate.window.height) * 0.05)
                    iconWidth: Math.max(40, Math.min(delegate.window.width, delegate.window.height) * 0.05)
                    source: "qrc:/ui/assets/images/bin-icon.svg"
                    toolTipText: qsTr("Delete transaction")
                    hoverColor: "red"

                    onClicked: {
                        delegate.transactionDelete(delegate.model);
                    }
                }
            }
        }
    }

    background: Item {
        Rectangle {
            anchors.fill: parent
            color: Material.foreground
            opacity: UI.Themes.currentTheme === "Dark" ? 0.025 : 0.08
            border.width: 0
        }

        Rectangle {
            color: Material.dividerColor
            height: 2
            width: parent.width
            anchors.bottom: parent.bottom
        }
    }
}
