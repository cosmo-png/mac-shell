import QtQuick

// The "liquid glass" surface: translucent fill, hairline edge, soft top highlight.
// Real blur comes from the compositor (see README).
Rectangle {
    color: Theme.glass
    radius: Theme.radius
    border.width: 1
    border.color: Theme.hairline

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: parent.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }
}
