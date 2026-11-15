import Quickshell
import QtQuick

Card {
    id: c
    width: 276
    height: 112

    SystemClock { id: clk; precision: SystemClock.Seconds }

    Column {
        x: 22
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -5
        spacing: 0

        Row {
            spacing: 8
            Txt {
                id: time
                text: Qt.formatDateTime(clk.date, Theme.clock24 ? "HH:mm" : "h:mm")
                font.pixelSize: 52
                font.weight: Font.Light
            }
            Txt {
                visible: !Theme.clock24
                anchors.baseline: time.baseline
                text: Qt.formatDateTime(clk.date, "AP")
                font.pixelSize: 17
                color: Theme.sub
            }
        }
        Txt { text: Qt.formatDateTime(clk.date, "dddd, MMMM d"); font.pixelSize: 13; color: Theme.sub }
    }

    // seconds line
    Rectangle {
        x: 20; y: parent.height - 18
        width: parent.width - 40; height: 3; radius: 1.5
        color: Qt.rgba(1, 1, 1, 0.10)
        Rectangle {
            height: parent.height; radius: 1.5
            width: parent.width * (clk.date.getSeconds() + 1) / 60
            Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.OutCubic } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.accent }
                GradientStop { position: 1.0; color: Theme.accent2 }
            }
        }
    }
}
