import Quickshell.Widgets
import QtQuick

// Glass card with a staggered entrance (fade + slide) and a soft hover lift.
Glass {
    id: c
    property int order: 0

    opacity: 0
    transform: Translate { id: tr; y: 26 }
    scale: hover.hovered ? 1.015 : 1
    border.color: hover.hovered ? Qt.rgba(1, 1, 1, 0.34) : Theme.hairline
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    HoverHandler { id: hover; onHoveredChanged: if (hovered) sweep.restart() }

    // a soft light sweep across the glass, only while it plays
    ClippingRectangle {
        anchors.fill: parent
        radius: c.radius
        color: "transparent"
        visible: sweep.running
        Rectangle {
            id: sheen
            y: -20
            width: 90
            height: parent.height + 40
            rotation: 18
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.11) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
    NumberAnimation { id: sweep; target: sheen; property: "x"; from: -110; to: c.width + 20; duration: 800; easing.type: Easing.InOutQuad }

    function replay() {
        opacity = 0
        tr.y = 26
        enter.restart()
    }
    Component.onCompleted: enter.restart()
    onVisibleChanged: if (visible) replay()

    SequentialAnimation {
        id: enter
        PauseAnimation { duration: 120 + c.order * 130 }
        ParallelAnimation {
            NumberAnimation { target: c; property: "opacity"; to: 1; duration: 450; easing.type: Easing.OutCubic }
            NumberAnimation { target: tr; property: "y"; to: 0; duration: 650; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }
    }
}
