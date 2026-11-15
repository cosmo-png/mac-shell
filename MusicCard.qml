import Quickshell
import Quickshell.Widgets
import QtQuick

Card {
    id: c
    width: 300
    height: 100

    readonly property var player: Media.player
    readonly property bool playing: Media.playing

    visible: player !== null

    ClippingRectangle {
        x: 14; y: 14
        width: 72; height: 72
        radius: 14
        color: Qt.rgba(1, 1, 1, 0.10)
        Image {
            anchors.fill: parent
            source: c.player ? c.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(160, 160)
            asynchronous: true
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 350 } }
        }
    }

    Column {
        x: 98; y: 16
        width: parent.width - 98 - 14
        Txt { text: c.player ? c.player.trackTitle : ""; font.pixelSize: 15; font.weight: Font.DemiBold; width: parent.width }
        Txt { text: c.player ? c.player.trackArtist : ""; font.pixelSize: 12; color: Theme.sub; width: parent.width }
    }

    Row {
        x: 98; y: 62
        height: 20
        spacing: 3
        Repeater {
            model: Media.count
            delegate: Rectangle {
                required property int index
                width: 3
                height: c.playing ? 3 + Media.levels[index] * 17 : 3
                y: parent.height - height
                radius: 1.5
                color: Qt.tint(Theme.accent, Qt.rgba(Theme.accent2.r, Theme.accent2.g, Theme.accent2.b, index / Media.count * 0.8))
                Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
            }
        }
    }

    Row {
        anchors { right: parent.right; rightMargin: 16 }
        y: 66
        spacing: 14
        Txt {
            text: "\u25C0\u25C0"
            MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: c.player.previous() }
        }
        Txt {
            text: c.playing ? "\u275A\u275A" : "\u25B6"
            MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: c.player.togglePlaying() }
        }
        Txt {
            text: "\u25B6\u25B6"
            MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: c.player.next() }
        }
    }
}
