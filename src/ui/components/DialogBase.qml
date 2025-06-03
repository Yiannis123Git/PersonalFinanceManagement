import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Dialog {
    id: dialog

    parent: Overlay.overlay // parent to top-level layer of app window
    anchors.centerIn: parent
    focus: true
    modal: true

    property alias acceptButtonText: acceptButton.text
    property alias rejectButtonText: rejectButton.text

    signal acceptButtonClicked
    signal rejectButtonClicked

    // Accept/reject buttons
    footer: DialogButtonBox {
        Button {
            id: acceptButton

            visible: text !== ""
            onClicked: {
                dialog.acceptButtonClicked();
            }
        }

        Button {
            id: rejectButton

            visible: text !== ""
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: {
                dialog.rejectButtonClicked();
            }
        }
    }

    Component.onCompleted: {
        dialog.visible = false;
    }
}
