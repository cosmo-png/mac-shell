pragma Singleton
import Quickshell
import QtQuick

// Everything you are likely to tweak lives here.
Singleton {
    readonly property string fontFamily: "Inter"
    readonly property color text: Qt.rgba(1, 1, 1, 0.92)
    readonly property color sub: Qt.rgba(1, 1, 1, 0.58)
    // accent presets. Change the default with `preset`, or cycle live: qs -c macshell ipc call macshell theme
    property int preset: 0
    readonly property var presets: [
        { name: "Ocean", a: "#0A84FF", b: "#BF5AF2" },
        { name: "Sunset", a: "#FF9F0A", b: "#FF375F" },
        { name: "Mint", a: "#30D158", b: "#0A84FF" },
        { name: "Rose", a: "#FF375F", b: "#BF5AF2" },
        { name: "Graphite", a: "#8E8E93", b: "#636366" }
    ]
    property color accent: presets[preset].a
    property color accent2: presets[preset].b
    Behavior on accent { ColorAnimation { duration: 500 } }
    Behavior on accent2 { ColorAnimation { duration: 500 } }
    readonly property color glass: Qt.rgba(0.10, 0.10, 0.12, 0.58)   // raise alpha if you have no blur
    readonly property color hairline: Qt.rgba(1, 1, 1, 0.16)
    readonly property color fill: Qt.rgba(1, 1, 1, 0.10)
    readonly property color fillHover: Qt.rgba(1, 1, 1, 0.17)
    readonly property real radius: 18
    readonly property int barHeight: 26
    readonly property real barAlpha: 0.22                            // 0 = fully transparent menu bar
    readonly property bool screenCorners: true                       // rounded screen corners
    readonly property real screenRadius: 14
    readonly property bool islandAlerts: true                        // new notifications pop the island open
    readonly property bool clock24: false                            // widgets clock: true for 24h
    readonly property string clockFormat: "ddd MMM d   h:mm AP"      // "ddd MMM d   HH:mm" for 24h

    // desktop file ids (see: ls /usr/share/applications). Missing apps are simply skipped.
    readonly property var pinned: ["firefox", "kitty", "org.kde.dolphin", "thunar", "code", "vesktop", "spotify"]

    readonly property var powerActions: [
        { label: "Lock Screen", cmd: ["loginctl", "lock-session"] },
        { label: "Sleep", cmd: ["systemctl", "suspend"] },
        { label: "Restart", cmd: ["systemctl", "reboot"] },
        { label: "Shut Down", cmd: ["systemctl", "poweroff"] },
        { label: "Log Out", cmd: ["hyprctl", "dispatch", "exit"] }
    ]
}
