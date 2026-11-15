import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick

PanelWindow {
    id: win

    property var shell
    property var notifs

    property string wifiName: ""
    property bool wifiOn: false
    property bool btOn: false
    property real brightness: 0.5

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var player: pickPlayer()

    function pickPlayer() {
        const ps = Mpris.players.values
        for (const p of ps) if (p.playbackState === MprisPlaybackState.Playing) return p
        return ps.length > 0 ? ps[0] : null
    }

    readonly property bool open: shell.centerOpen
    visible: open || card.opacity > 0.01
    anchors { top: true; right: true }
    margins { top: Theme.barHeight + 6; right: 10 }
    implicitWidth: 360
    implicitHeight: body.implicitHeight + 24
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "macshell-center"

    // status is read only while the panel is open: no background polling
    Process {
        id: wifiState
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = ""
                for (const l of text.split("\n")) if (l.startsWith("yes:")) { name = l.slice(4); break }
                win.wifiName = name
            }
        }
    }
    Process {
        id: wifiRadio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: win.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: btState
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector { onStreamFinished: win.btOn = /Powered:\s+yes/.test(text) }
    }
    Process {
        id: bright
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",")
                if (p.length >= 4) win.brightness = parseInt(p[3]) / 100
            }
        }
    }
    function refresh() {
        wifiState.running = true
        wifiRadio.running = true
        btState.running = true
        bright.running = true
    }
    onOpenChanged: if (open) refresh()

    Timer {
        id: brightTimer
        interval: 80
        onTriggered: Quickshell.execDetached(["brightnessctl", "set", Math.max(1, Math.round(win.brightness * 100)) + "%"])
    }

    PwObjectTracker { objects: win.sink ? [win.sink] : [] }

    HyprlandFocusGrab {
        windows: [win]
        active: win.open
        onCleared: {
            win.shell.centerClosedAt = Date.now()
            win.shell.centerOpen = false
        }
    }

    Glass {
        id: card
        anchors.fill: parent
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.92
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }

        Column {
            id: body
            x: 12; y: 12
            width: parent.width - 24
            spacing: 10

            Row {
                spacing: 10
                Tile {
                    width: (body.width - 10) / 2
                    title: "Wi-Fi"
                    sub: win.wifiOn ? (win.wifiName || "On") : "Off"
                    glyph: "\u2248"
                    active: win.wifiOn
                    onClicked: {
                        Quickshell.execDetached(["nmcli", "radio", "wifi", win.wifiOn ? "off" : "on"])
                        win.wifiOn = !win.wifiOn
                    }
                }
                Tile {
                    width: (body.width - 10) / 2
                    title: "Bluetooth"
                    sub: win.btOn ? "On" : "Off"
                    glyph: "B"
                    active: win.btOn
                    onClicked: {
                        Quickshell.execDetached(["bluetoothctl", "power", win.btOn ? "off" : "on"])
                        win.btOn = !win.btOn
                    }
                }
            }
            Tile {
                width: body.width
                title: "Do Not Disturb"
                sub: win.shell.dnd ? "On" : "Off"
                glyph: "\u263E"
                active: win.shell.dnd
                onClicked: win.shell.dnd = !win.shell.dnd
            }

            MacSlider {
                width: body.width
                label: "\u2600"
                value: win.brightness
                onMoved: v => {
                    win.brightness = v
                    brightTimer.restart()
                }
            }
            MacSlider {
                width: body.width
                label: "\u266A"
                value: win.sink && win.sink.audio ? Math.min(1, win.sink.audio.volume) : 0
                onMoved: v => {
                    if (win.sink && win.sink.audio) {
                        win.sink.audio.muted = false
                        win.sink.audio.volume = v
                    }
                }
            }

            // now playing
            Rectangle {
                visible: win.player !== null
                width: body.width
                height: 64
                radius: 16
                color: Theme.fill

                Column {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 150
                    Txt { text: win.player ? win.player.trackTitle : ""; font.weight: Font.DemiBold; width: parent.width }
                    Txt { text: win.player ? win.player.trackArtist : ""; font.pixelSize: 12; color: Theme.sub; width: parent.width }
                }
                Row {
                    anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                    spacing: 16
                    Txt {
                        text: "\u25C0\u25C0"
                        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: win.player.previous() }
                    }
                    Txt {
                        text: win.player && win.player.playbackState === MprisPlaybackState.Playing ? "\u275A\u275A" : "\u25B6"
                        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: win.player.togglePlaying() }
                    }
                    Txt {
                        text: "\u25B6\u25B6"
                        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: win.player.next() }
                    }
                }
            }

            // notification history
            Item {
                width: body.width
                height: 20
                Txt { anchors.verticalCenter: parent.verticalCenter; text: "Notifications"; font.weight: Font.DemiBold }
                Txt {
                    visible: list.count > 0
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: "Clear"
                    color: Theme.accent
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: win.notifs.trackedNotifications.values.slice().forEach(n => n.dismiss())
                    }
                }
            }
            Txt { visible: list.count === 0; text: "No notifications"; color: Theme.sub }
            ListView {
                id: list
                visible: count > 0
                width: body.width
                height: Math.min(contentHeight, 280)
                clip: true
                spacing: 8
                verticalLayoutDirection: ListView.BottomToTop
                model: win.notifs.trackedNotifications

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: nc.implicitHeight + 20
                    radius: 14
                    color: Theme.fill

                    Column {
                        id: nc
                        x: 12; y: 10
                        width: parent.width - 24
                        spacing: 2
                        Txt { text: modelData.appName; font.pixelSize: 11; color: Theme.sub; width: parent.width }
                        Txt { text: modelData.summary; font.weight: Font.DemiBold; width: parent.width }
                        Txt {
                            visible: text !== ""
                            text: modelData.body
                            font.pixelSize: 12
                            color: Theme.sub
                            width: parent.width
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            textFormat: Text.PlainText
                        }
                    }
                    MouseArea { anchors.fill: parent; onClicked: modelData.dismiss() }
                }
            }
        }
    }
}
