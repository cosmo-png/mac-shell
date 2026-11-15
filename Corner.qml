import QtQuick
import QtQuick.Shapes

// One rounded screen corner (top-left piece; rotate it for the others).
Shape {
    id: s
    property real r: Theme.screenRadius
    width: r
    height: r
    transformOrigin: Item.Center
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "black"
        strokeColor: "transparent"
        startX: 0; startY: 0
        PathLine { x: s.r; y: 0 }
        PathArc { x: 0; y: s.r; radiusX: s.r; radiusY: s.r; direction: PathArc.Counterclockwise }
        PathLine { x: 0; y: 0 }
    }
}
