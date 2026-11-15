import Quickshell
import Quickshell.Wayland
import QtQuick

// Desktop widgets: sit on the bottom layer, so windows cover them.
PanelWindow {
    id: win

    property var shell

    visible: fade.opacity > 0
    anchors { top: true; right: true }
    margins { top: Theme.barHeight + 18; right: 22 }
    implicitWidth: 300
    implicitHeight: col.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "macshell-widgets"

    Item {
        id: fade
        anchors.fill: parent
        opacity: win.shell.widgetsOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

        Column {
            id: col
            spacing: 14
            ClockCard { order: 0 }
            StatsCard { order: 1 }
            CalendarCard { order: 2 }
            MusicCard { order: 3 }
        }
    }
}
