import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// Volume / brightness pop-up. Volume shows itself; brightness is triggered by a keybind (see README).
PanelWindow {
    id: win

    property bool shown: false
    property bool armed: false
    property string glyph: "\u266A"
    property real level: 0
    property bool muted: false

    readonly property var sink: Pipewire.defaultAudioSink

    function show(g, lvl, mute) {
        glyph = g
        level = Math.max(0, Math.min(1, lvl))
        muted = mute
        shown = true
        hide.restart()
    }
    function showBrightness() { bright.running = true }

    visible: shown
    anchors.bottom: true
    margins.bottom: 110
    implicitWidth: 250
    implicitHeight: 52
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}          // click-through
    WlrLayershell.namespace: "macshell-osd"

    PwObjectTracker { objects: win.sink ? [win.sink] : [] }

    Connections {
        target: win.sink && win.sink.audio ? win.sink.audio : null
        ignoreUnknownSignals: true
        function onVolumeChanged() { if (win.armed) win.show("\u266A", win.sink.audio.volume, win.sink.audio.muted) }
        function onMutedChanged() { if (win.armed) win.show("\u266A", win.sink.audio.volume, win.sink.audio.muted) }
    }

    Timer { id: hide; interval: 1400; onTriggered: win.shown = false }
    Timer { interval: 2500; running: true; onTriggered: win.armed = true }   // ignore start-up noise

    Process {
        id: bright
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",")
                if (p.length >= 4) win.show("\u2600", parseInt(p[3]) / 100, false)
            }
        }
    }

    Glass {
        anchors.fill: parent
        radius: 26

        Row {
            anchors.centerIn: parent
            spacing: 12
            Txt { anchors.verticalCenter: parent.verticalCenter; text: win.muted ? "\u00D7" : win.glyph; font.pixelSize: 18 }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Repeater {
                    model: 16
                    delegate: Rectangle {
                        required property int index
                        width: 7; height: 12; radius: 2
                        color: !win.muted && index < Math.round(win.level * 16) ? Theme.text : Qt.rgba(1, 1, 1, 0.22)
                    }
                }
            }
        }
    }
}
