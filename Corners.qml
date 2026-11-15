import Quickshell
import Quickshell.Wayland
import QtQuick

// Rounded screen corners like a Mac display. Click-through, drawn once, costs nothing afterwards.
PanelWindow {
    id: win

    visible: Theme.screenCorners
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "macshell-corners"

    Corner { anchors { top: parent.top; left: parent.left } }
    Corner { anchors { top: parent.top; right: parent.right }; rotation: 90 }
    Corner { anchors { bottom: parent.bottom; right: parent.right }; rotation: 180 }
    Corner { anchors { bottom: parent.bottom; left: parent.left }; rotation: 270 }
}
