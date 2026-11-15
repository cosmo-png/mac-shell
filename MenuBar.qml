import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick

PanelWindow {
    id: bar

    property var shell
    property bool menuOpen: false

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "macshell-bar"

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function appName() {
        const t = ToplevelManager.activeToplevel
        if (!t) return "Desktop"
        const e = DesktopEntries.heuristicLookup(t.appId)
        return e ? e.name : (t.appId || t.title)
    }

    // red = close, yellow = minimize (parks the window on a hidden workspace, the dock brings it back),
    // green = maximize (hold Alt for real fullscreen)
    function windowAction(i, alt) {
        if (i === 0) Hyprland.dispatch("killactive")
        else if (i === 1) Hyprland.dispatch("movetoworkspacesilent special:minimized")
        else Hyprland.dispatch(alt ? "fullscreen 0" : "fullscreen 1")
    }

    // transparent-ish bar background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, Theme.barAlpha)
        WheelHandler {   // mouse wheel over the bar changes workspace
            acceptedDevices: PointerDevice.Mouse
            onWheel: e => Hyprland.dispatch(e.angleDelta.y > 0 ? "workspace e-1" : "workspace e+1")
        }
    }

    // ---------------- left: logo, active app, workspaces
    Row {
        anchors { left: parent.left; leftMargin: 10 }
        height: parent.height
        spacing: 9

        Rectangle {
            width: 14; height: 14; radius: 4
            anchors.verticalCenter: parent.verticalCenter
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.accent }
                GradientStop { position: 1.0; color: "#BF5AF2" }
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                onClicked: bar.menuOpen = !bar.menuOpen
            }
        }

        Row {
            id: lights
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            readonly property bool hasWin: ToplevelManager.activeToplevel !== null
            opacity: hasWin ? 1 : 0.4
            Behavior on opacity { NumberAnimation { duration: 200 } }
            HoverHandler { id: lightsHover }

            Repeater {
                model: [
                    { c: "#FF5F57", g: "\u00D7" },
                    { c: "#FEBC2E", g: "\u2212" },
                    { c: "#28C840", g: "+" }
                ]
                delegate: Rectangle {
                    id: dot
                    required property var modelData
                    required property int index
                    width: 12; height: 12; radius: 6
                    color: lights.hasWin ? modelData.c : "#5a5a5e"
                    scale: ma.pressed ? 0.85 : (ma.containsMouse ? 1.18 : 1)
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                    Txt {
                        anchors.centerIn: parent
                        text: dot.modelData.g
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Qt.rgba(0, 0, 0, 0.6)
                        opacity: lightsHover.hovered && lights.hasWin ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        anchors.margins: -2
                        hoverEnabled: true
                        enabled: lights.hasWin
                        onClicked: m => bar.windowAction(dot.index, (m.modifiers & Qt.AltModifier) !== 0)
                    }
                }
            }
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.appName()
            font.weight: Font.DemiBold
            width: Math.min(implicitWidth, 150)
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Repeater {
                model: Hyprland.workspaces
                delegate: Rectangle {
                    required property var modelData
                    visible: modelData.id > 0
                    width: modelData.focused ? 16 : 6
                    height: 6
                    radius: 3
                    color: modelData.focused ? Theme.text : Qt.rgba(1, 1, 1, 0.4)
                    Behavior on width { NumberAnimation { duration: 120 } }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                    }
                }
            }
        }
    }

    // ---------------- right: tray, battery, control center, clock
    Row {
        anchors { right: parent.right; rightMargin: 10 }
        height: parent.height
        spacing: 8

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Repeater {
                model: SystemTray.items
                delegate: Item {
                    id: trayItem
                    required property var modelData
                    width: 16; height: 16
                    Image {
                        anchors.fill: parent
                        source: trayItem.modelData.icon
                        sourceSize: Qt.size(32, 32)
                        smooth: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: m => {
                            if (m.button === Qt.LeftButton) trayItem.modelData.activate()
                            else if (trayItem.modelData.hasMenu) {
                                const p = trayItem.mapToItem(null, 0, bar.height)
                                trayItem.modelData.display(bar, p.x, bar.height)
                            }
                        }
                    }
                }
            }
        }

        Row {
            id: batt
            visible: UPower.displayDevice.isPresent
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            readonly property real pct: {
                const p = UPower.displayDevice.percentage
                return p > 1 ? p / 100 : p
            }
            readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging

            Txt {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(batt.pct * 100) + "%"
                font.pixelSize: 12
            }
            Item {
                width: 25; height: 12
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 22; height: 12; radius: 3.5
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.55)
                    Rectangle {
                        x: 2; y: 2; height: 8; radius: 2
                        width: Math.max(2, 18 * batt.pct)
                        color: batt.charging ? "#32D74B" : (batt.pct < 0.2 ? "#FF453A" : Theme.text)
                    }
                }
                Rectangle { x: 23; y: 4; width: 2; height: 4; radius: 1; color: Qt.rgba(1, 1, 1, 0.55) }
            }
        }

        Item {
            width: 18; height: 14
            anchors.verticalCenter: parent.verticalCenter
            Column {
                anchors.centerIn: parent
                spacing: 3
                Repeater {
                    model: 2
                    delegate: Rectangle { width: 16; height: 5; radius: 2.5; color: Qt.rgba(1, 1, 1, 0.85) }
                }
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onClicked: bar.shell.toggleCenter()
            }
        }

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, Theme.clockFormat)
            MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: bar.shell.toggleCenter() }
        }
    }

    // ---------------- logo menu (power actions)
    PopupWindow {
        id: power
        anchor.window: bar
        anchor.rect.x: 8
        anchor.rect.y: bar.height + 2
        anchor.rect.width: 1
        anchor.rect.height: 1
        implicitWidth: 190
        implicitHeight: menuCol.implicitHeight + 16
        visible: bar.menuOpen
        color: "transparent"

        Glass {
            anchors.fill: parent
            radius: 12
            Column {
                id: menuCol
                x: 8; y: 8
                width: parent.width - 16
                Repeater {
                    model: Theme.powerActions
                    delegate: Rectangle {
                        required property var modelData
                        width: menuCol.width
                        height: 28
                        radius: 6
                        color: hov.containsMouse ? Theme.accent : "transparent"
                        Txt { x: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData.label }
                        MouseArea {
                            id: hov
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                bar.menuOpen = false
                                Quickshell.execDetached(modelData.cmd)
                            }
                        }
                    }
                }
            }
        }
    }

    HyprlandFocusGrab {
        windows: [power, bar]
        active: bar.menuOpen
        onCleared: bar.menuOpen = false
    }
}
