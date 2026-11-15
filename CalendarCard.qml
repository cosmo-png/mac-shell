import Quickshell
import QtQuick

Card {
    id: c
    width: 276
    height: 224

    SystemClock { id: clk; precision: SystemClock.Minutes }

    readonly property var today: clk.date
    readonly property int firstDow: new Date(today.getFullYear(), today.getMonth(), 1).getDay()
    readonly property int days: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()

    Txt { x: 19; y: 14; text: Qt.formatDateTime(c.today, "MMMM yyyy"); font.pixelSize: 15; font.weight: Font.DemiBold }

    Row {
        x: 19; y: 43
        Repeater {
            model: ["S", "M", "T", "W", "T", "F", "S"]
            delegate: Item {
                required property string modelData
                width: 34; height: 20
                Txt { anchors.centerIn: parent; text: modelData; font.pixelSize: 11; color: Theme.sub }
            }
        }
    }

    Grid {
        x: 19; y: 65
        columns: 7
        Repeater {
            model: 42
            delegate: Item {
                id: cell
                required property int index
                readonly property int day: index - c.firstDow + 1
                readonly property bool inMonth: day >= 1 && day <= c.days
                readonly property bool isToday: inMonth && day === c.today.getDate()
                property real pop: 0
                width: 34; height: 25

                Component.onCompleted: pop = isToday ? 1 : 0
                onIsTodayChanged: pop = isToday ? 1 : 0
                Behavior on pop { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }

                Rectangle {
                    visible: cell.pop > 0
                    anchors.centerIn: parent
                    width: 22; height: 22; radius: 11
                    scale: cell.pop
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.accent }
                        GradientStop { position: 1.0; color: Theme.accent2 }
                    }
                }
                Txt {
                    anchors.centerIn: parent
                    visible: cell.inMonth
                    text: cell.day
                    font.pixelSize: 12
                    font.weight: cell.isToday ? Font.DemiBold : Font.Normal
                    color: cell.isToday ? "white" : Theme.text
                }
            }
        }
    }
}
