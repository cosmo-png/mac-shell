import QtQuick

Rectangle {
    id: t
    property string title
    property string sub
    property string glyph
    property bool active: false
    signal clicked()

    implicitHeight: 62
    radius: 16
    color: active ? Theme.accent : (mouse.containsMouse ? Theme.fillHover : Theme.fill)
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Rectangle {
            width: 34; height: 34; radius: 17
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1, 1, 1, t.active ? 0.25 : 0.12)
            Txt { anchors.centerIn: parent; text: t.glyph; font.pixelSize: 15; color: "white" }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Txt { text: t.title; font.weight: Font.DemiBold; color: "white"; width: t.width - 70 }
            Txt { text: t.sub; font.pixelSize: 11; color: Qt.rgba(1, 1, 1, 0.65); width: t.width - 70 }
        }
    }

    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: t.clicked() }
}
