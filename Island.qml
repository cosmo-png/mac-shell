import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

// Dynamic island: a black pill in the middle of the menu bar.
//   idle     hidden
//   compact  music is playing: live bars + title
//   open     hover the pill: album art, controls
//   alert    a new notification pops it open for a few seconds
PanelWindow {
    id: win

    property var shell
    property var alertItem: null

    function alert(n) {
        if (!Theme.islandAlerts) return
        alertItem = n
        alertTimer.restart()
    }
    Timer { id: alertTimer; interval: 4200; onTriggered: win.alertItem = null }

    readonly property var player: Media.player
    readonly property string mode: alertItem !== null ? "alert"
        : (player !== null && hover.hovered ? "open"
        : (Media.playing ? "compact" : "idle"))

    anchors.top: true
    implicitWidth: 400
    implicitHeight: 130
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region { item: pill }
    WlrLayershell.namespace: "macshell-island"

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: 2
        width: win.mode === "open" ? 380 : (win.mode === "alert" ? 340 : (win.mode === "compact" ? 230 : 44))
        height: win.mode === "open" ? 112 : (win.mode === "alert" ? 60 : (win.mode === "compact" ? 28 : 0))
        radius: Math.min(height / 2, 24)
        color: "black"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.14)
        clip: true
        visible: height > 0.5
        opacity: win.mode === "idle" ? 0 : 1

        Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        HoverHandler { id: hover }

        // ---- compact
        Item {
            anchors.fill: parent
            opacity: win.mode === "compact" ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Row {
                anchors.centerIn: parent
                spacing: 10
                Row {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: 5
                        delegate: Rectangle {
                            required property int index
                            width: 3
                            height: 4 + Media.levels[index * 2] * 12
                            radius: 1.5
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.accent
                            Behavior on height { NumberAnimation { duration: 80 } }
                        }
                    }
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.player ? win.player.trackTitle : ""
                    font.pixelSize: 12
                    width: Math.min(implicitWidth, 150)
                }
            }
        }

        // ---- open
        Item {
            anchors.fill: parent
            opacity: win.mode === "open" ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 220 } }

            ClippingRectangle {
                x: 14; y: 14
                width: 84; height: 84
                radius: 14
                color: Qt.rgba(1, 1, 1, 0.10)
                Image {
                    anchors.fill: parent
                    source: win.player ? win.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(180, 180)
                    asynchronous: true
                }
            }
            Column {
                x: 112; y: 16
                width: parent.width - 112 - 16
                Txt { text: win.player ? win.player.trackTitle : ""; font.pixelSize: 15; font.weight: Font.DemiBold; width: parent.width }
                Txt { text: win.player ? win.player.trackArtist : ""; font.pixelSize: 12; color: Theme.sub; width: parent.width }
            }
            Row {
                x: 112; y: 70
                spacing: 22
                Txt { text: "\u25C0\u25C0"; font.pixelSize: 15; MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: win.player.previous() } }
                Txt { text: Media.playing ? "\u275A\u275A" : "\u25B6"; font.pixelSize: 15; MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: win.player.togglePlaying() } }
                Txt { text: "\u25B6\u25B6"; font.pixelSize: 15; MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: win.player.next() } }
            }
            Row {
                x: parent.width - width - 18
                y: 62
                height: 32
                spacing: 2
                Repeater {
                    model: 6
                    delegate: Rectangle {
                        required property int index
                        width: 3
                        height: Media.playing ? 4 + Media.levels[index * 2] * 26 : 4
                        y: parent.height - height
                        radius: 1.5
                        color: Theme.accent
                        Behavior on height { NumberAnimation { duration: 80 } }
                    }
                }
            }
        }

        // ---- alert
        Item {
            anchors.fill: parent
            opacity: win.mode === "alert" ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Image {
                x: 14; y: 12
                width: 36; height: 36
                sourceSize: Qt.size(72, 72)
                smooth: true
                source: win.alertItem ? (win.alertItem.image !== "" ? win.alertItem.image
                        : Quickshell.iconPath(win.alertItem.appIcon, "dialog-information")) : ""
            }
            Column {
                x: 62; y: 12
                width: parent.width - 62 - 14
                Txt { text: win.alertItem ? win.alertItem.appName : ""; font.pixelSize: 11; color: Theme.sub; width: parent.width }
                Txt { text: win.alertItem ? win.alertItem.summary : ""; font.weight: Font.DemiBold; width: parent.width }
            }
        }
    }
}
