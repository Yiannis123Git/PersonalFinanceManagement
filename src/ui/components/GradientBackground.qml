import QtQuick
import QtQuick.Controls.Material

Rectangle {
    id: gradientBackground

    property color gradientColor: Material.background

    anchors.fill: parent
    z: -1 // Ensure background stays behind other elements

    gradient: Gradient {
        GradientStop {
            position: 0.0
        }
        GradientStop {
            position: 0.7
        }
        GradientStop {
            position: 1.0
        }
    }

    // Update gradient stops based on the current theme (QML does not do this automatically prob due qt func call)
    Component.onCompleted: {
        gradient.stops[0].color = Qt.binding(function () {
            return gradientColor;
        });
        gradient.stops[1].color = Qt.binding(function () {
            if (Material.theme === Material.Light) {
                return Qt.darker(gradientColor, 1.05);
            } else {
                return Qt.lighter(gradientColor, 1.005);
            }
        });
        gradient.stops[2].color = Qt.binding(function () {
            if (Material.theme === Material.Light) {
                return Qt.darker(gradientColor, 1.1);
            } else {
                return Qt.lighter(gradientColor, 1.01);
            }
        });
    }
}
