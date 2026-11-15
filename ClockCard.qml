import Quickshell
import QtQuick

Card {
    id: c
    width: 300
    height: 150

    SystemClock { id: clk; precision: SystemClock.Seconds }

    Column {
        x: 22
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -8
        spacing: 0

        Row {
            spacing: 8
            Txt {
                id: time
                text: Qt.formatDateTime(clk.date, Theme.clock24 ? "HH:mm" : "h:mm")
                font.pixelSize: 66
                font.weight: Font.Light
            }
            Txt {
                visible: !Theme.clock24
                anchors.baseline: time.baseline
                text: Qt.formatDateTime(clk.date, "AP")
                font.pixelSize: 20
                color: Theme.sub
            }
        }
        Txt { text: Qt.formatDateTime(clk.date, "dddd, MMMM d"); font.pixelSize: 15; color: Theme.sub }
    }

    // seconds line
    Rectangle {
        x: 22; y: parent.height - 24
        width: parent.width - 44; height: 3; radius: 1.5
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
