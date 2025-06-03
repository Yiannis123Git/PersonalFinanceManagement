import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

import ".." as UI // Enable themes sigleton use

ItemDelegate {
    id: delegate

    required property var model
    required property ApplicationWindow window // we use this to avoid null errors during model deletions

    signal monthlyTransactionEdit(var model)
    signal monthlyTransactionDelete(var model)

    width: parent ? parent.width : 0 // Avoid null error during model deletions
    height: 100
    padding: Math.max(40, delegate.window.width * 0.04)

    function _getOrdinalSuffix(day) {
        if (day >= 11 && day <= 13) {
            return day + "th";
        }

        switch (day % 10) {
        case 1:
            return day + "st";
        case 2:
            return day + "nd";
        case 3:
            return day + "rd";
        default:
            return day + "th";
        }
    }

    contentItem: Item {
        id: contentItem
        property string endDateText: delegate.model.endDate ? qsTr("End date: ") + delegate.model.endDate.toLocaleDateString(Qt.locale(), "dd MMMM yyyy") : qsTr("End date: No End Date")

        RowLayout {
            anchors.fill: parent

            // Start date and end date
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1

                spacing: 5

                Text {
                    Layout.fillWidth: true

                    text: qsTr("Start date: " + delegate.model.startDate.toLocaleDateString(Qt.locale(), "dd MMMM yyyy"))
                    color: Material.foreground
                    font.weight: Font.StyleItalic
                    font.pointSize: Math.max(16, Math.min(delegate.window.width, delegate.window.height) * 0.02)
                }

                Text {
                    Layout.fillWidth: true

                    text: qsTr(contentItem.endDateText)
                    color: Material.foreground
                    font.weight: Font.StyleItalic
                    font.pointSize: Math.max(16, Math.min(delegate.window.width, delegate.window.height) * 0.02)
                }
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
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: Math.max(40, delegate.window.width * 0.1)

                Text {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1

                    text: delegate.model.amount + "€"
                    font.pointSize: Math.max(20, Math.min(delegate.window.width, delegate.window.height) * 0.025)
                    color: delegate.model.type === "income" ? "green" : "red"
                }

                // Day of month
                Text {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1

                    text: qsTr("Monthly on the ") + delegate._getOrdinalSuffix(delegate.model.dayOfMonth)
                    color: Material.foreground
                    font.pointSize: Math.max(16, Math.min(delegate.window.width, delegate.window.height) * 0.02)
                }
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
                    toolTipText: qsTr("Edit monthly recurring transaction")

                    onClicked: {
                        delegate.monthlyTransactionEdit(delegate.model);
                    }
                }

                // Delete button
                IconButton {
                    iconColor: Material.foreground
                    iconHeight: Math.max(40, Math.min(delegate.window.width, delegate.window.height) * 0.05)
                    iconWidth: Math.max(40, Math.min(delegate.window.width, delegate.window.height) * 0.05)
                    source: "qrc:/ui/assets/images/bin-icon.svg"
                    toolTipText: qsTr("Delete monthly recurring transaction")
                    hoverColor: "red"

                    onClicked: {
                        delegate.monthlyTransactionDelete(delegate.model);
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
