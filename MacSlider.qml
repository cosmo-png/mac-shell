import QtQuick

Item {
    id: s
    property real value: 0
    property string label: ""
    signal moved(real v)

    implicitHeight: 34

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.fill

        Rectangle {
            width: Math.max(parent.height, parent.width * s.value)
            height: parent.height
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.92)
        }
        Txt {
            x: 13
            anchors.verticalCenter: parent.verticalCenter
            text: s.label
            font.pixelSize: 15
            color: s.value > 0.08 ? "#2a2a2e" : Theme.sub
        }
    }

    MouseArea {
        anchors.fill: parent
        function set(mx) { s.moved(Math.max(0, Math.min(1, mx / width))) }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x) }
    }
}
