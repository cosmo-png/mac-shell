import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick

// Banner notifications (top right). History lives in the Control Center.
PanelWindow {
    id: win

    property var list: []
    function add(n) { list = list.concat([n]) }
    function remove(n) { list = list.filter(x => x !== n) }

    visible: list.length > 0
    anchors { top: true; right: true }
    margins { top: Theme.barHeight + 8; right: 10 }
    implicitWidth: 360
    implicitHeight: col.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "macshell-notify"

    Column {
        id: col
        width: parent.width
        spacing: 8

        Repeater {
            model: win.list
            delegate: Glass {
                id: card
                required property var modelData
                width: col.width
                height: content.implicitHeight + 24
                radius: 16

                NumberAnimation on opacity { from: 0; to: 1; duration: 160 }
                transform: Translate { id: slide }
                NumberAnimation { target: slide; property: "x"; from: 46; to: 0; duration: 420; easing.type: Easing.OutBack; running: true }

                // banners fade away after a few seconds, critical ones stay
                Timer {
                    interval: 5500
                    running: card.modelData.urgency !== NotificationUrgency.Critical
                    onTriggered: win.remove(card.modelData)
                }
                Connections {
                    target: card.modelData
                    function onClosed(reason) { win.remove(card.modelData) }
                }

                Column {
                    id: content
                    x: 12; y: 12
                    width: parent.width - 24
                    spacing: 8

                    Row {
                        spacing: 10
                        Image {
                            width: 36; height: 36
                            sourceSize: Qt.size(72, 72)
                            smooth: true
                            source: card.modelData.image !== "" ? card.modelData.image
                                  : Quickshell.iconPath(card.modelData.appIcon, "dialog-information")
                        }
                        Column {
                            width: content.width - 46
                            spacing: 2
                            Txt { text: card.modelData.appName; font.pixelSize: 11; color: Theme.sub; width: parent.width }
                            Txt { text: card.modelData.summary; font.weight: Font.DemiBold; width: parent.width }
                            Txt {
                                visible: text !== ""
                                text: card.modelData.body
                                font.pixelSize: 12
                                color: Theme.sub
                                width: parent.width
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                textFormat: Text.PlainText
                            }
                        }
                    }

                    Row {
                        spacing: 8
                        visible: card.modelData.actions.length > 0
                        Repeater {
                            model: card.modelData.actions
                            delegate: Rectangle {
                                required property var modelData
                                height: 26
                                width: label.implicitWidth + 24
                                radius: 13
                                color: Theme.fill
                                Txt { id: label; anchors.centerIn: parent; text: modelData.text; font.pixelSize: 12 }
                                MouseArea { anchors.fill: parent; onClicked: modelData.invoke() }
                            }
                        }
                    }
                }

                // time left before the banner fades away
                Rectangle {
                    visible: card.modelData.urgency !== NotificationUrgency.Critical
                    x: 14
                    y: parent.height - 6
                    height: 2
                    radius: 1
                    color: Theme.accent
                    opacity: 0.7
                    NumberAnimation on width { from: card.width - 28; to: 0; duration: 5500 }
                }

                // click the banner to dismiss it
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    onClicked: card.modelData.dismiss()
                }
            }
        }
    }
}
