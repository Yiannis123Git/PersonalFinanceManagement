import QtQuick

Item {
    id: windowResizer
    anchors.fill: parent
    property int borderWidth: 5
    readonly property int borderWidthModifier: 10
    property var targetWindow: null

    // handle cursor icon changes to indicate resizing
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: {
            const mousePos = Qt.point(mouseX, mouseY);
            const border = windowResizer.borderWidth + windowResizer.borderWidthModifier; // Increase the corner size slightly

            if (windowResizer.targetWindow.visibility === Window.FullScreen) {
                return;
            }

            if (mousePos.x < border && mousePos.y < border)
                return Qt.SizeFDiagCursor;
            if (mousePos.x >= width - border && mousePos.y >= height - border)
                return Qt.SizeFDiagCursor;
            if (mousePos.x >= width - border && mousePos.y < border)
                return Qt.SizeBDiagCursor;
            if (mousePos.x < border && mousePos.y >= height - border)
                return Qt.SizeBDiagCursor;
            if (mousePos.x < border || mousePos.x >= width - border)
                return Qt.SizeHorCursor;
            if (mousePos.y < border || mousePos.y >= height - border)
                return Qt.SizeVerCursor;
        }

        acceptedButtons: Qt.NoButton // disable mouse events
    }

    // Handle window resizing
    DragHandler {
        id: resizeHandler
        grabPermissions: DragHandler.TakeOverForbidden
        target: null
        onActiveChanged: if (active) {
            const mousePos = resizeHandler.centroid.position;
            const border = windowResizer.borderWidth + windowResizer.borderWidthModifier; // Increase the corner size slightly

            let e = 0;
            if (mousePos.x < border) {
                e |= Qt.LeftEdge;
            }
            if (mousePos.x >= windowResizer.width - border) {
                e |= Qt.RightEdge;
            }
            if (mousePos.y < border) {
                e |= Qt.TopEdge;
            }
            if (mousePos.y >= windowResizer.height - border) {
                e |= Qt.BottomEdge;
            }

            windowResizer.targetWindow.startSystemResize(e);
        }
    }
}
