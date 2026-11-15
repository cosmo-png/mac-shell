import QtQuick
import QtQuick.Shapes

// Animated progress ring. Turns orange / red when the value gets high.
Item {
    id: r
    property real value: 0
    property string text: ""
    property string label: ""
    property real thickness: 8
    readonly property color tint: value > 0.85 ? "#FF453A" : (value > 0.6 ? "#FF9F0A" : Theme.accent)

    implicitWidth: 78
    implicitHeight: 98
    Behavior on value { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }

    Shape {
        id: sh
        width: 78; height: 78
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Qt.rgba(1, 1, 1, 0.10)
            strokeWidth: r.thickness
            fillColor: "transparent"
            PathAngleArc {
                centerX: 39; centerY: 39
                radiusX: 39 - r.thickness / 2; radiusY: 39 - r.thickness / 2
                startAngle: 0; sweepAngle: 360
            }
        }
        ShapePath {
            strokeColor: r.tint
            strokeWidth: r.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 39; centerY: 39
                radiusX: 39 - r.thickness / 2; radiusY: 39 - r.thickness / 2
                startAngle: -90
                sweepAngle: 360 * Math.max(0.002, Math.min(1, r.value))
            }
        }
    }
    Txt { anchors.centerIn: sh; text: r.text; font.pixelSize: 17; font.weight: Font.DemiBold }
    Txt { anchors.horizontalCenter: parent.horizontalCenter; y: 84; text: r.label; font.pixelSize: 11; color: Theme.sub }
}
