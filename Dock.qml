import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: win

    property var shell
    readonly property int icon: 40
    readonly property int gap: 8
    readonly property int pad: 8

    // pinned apps first, then anything else that is running
    property var items: build()

    function build() {
        const groups = {}
        for (const t of ToplevelManager.toplevels.values) {
            const k = (t.appId || "").toLowerCase()
            if (k === "") continue
            if (!groups[k]) groups[k] = []
            groups[k].push(t)
        }
        const out = []
        const seen = {}
        const add = (key, appId, wins) => {
            const e = DesktopEntries.heuristicLookup(appId)
            if (!e && wins.length === 0) return
            seen[key] = true
            out.push({ key: key, entry: e, name: e ? e.name : appId, icon: e ? e.icon : appId, windows: wins })
        }
        for (const id of Theme.pinned) add(id.toLowerCase(), id, groups[id.toLowerCase()] || [])
        for (const k in groups) if (!seen[k]) add(k, groups[k][0].appId, groups[k])
        return out
    }

    // minimized windows are parked on the hidden "special:minimized" workspace
    function hyprOf(t) {
        for (const h of Hyprland.toplevels.values) if (h.wayland === t) return h
        return null
    }
    function isMin(t) {
        const h = hyprOf(t)
        return h !== null && h.workspace !== null && h.workspace.name === "special:minimized"
    }
    function restore(t) {
        const h = hyprOf(t)
        if (!h) return
        const a = h.address.startsWith("0x") ? h.address : "0x" + h.address
        Hyprland.dispatch("movetoworkspacesilent " + Hyprland.focusedWorkspace.id + ",address:" + a)
        Hyprland.dispatch("focuswindow address:" + a)
    }

    anchors.bottom: true
    margins.bottom: 6
    implicitWidth: pill.width + 80
    implicitHeight: pill.height + 42
    exclusiveZone: pill.height + 12
    color: "transparent"
    mask: Region { item: hit }
    WlrLayershell.namespace: "macshell-dock"

    Item {
        id: hit
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: pill.width
        height: pill.height + 40

        HoverHandler { id: hover }

        readonly property int hoverIndex: hover.hovered
            ? Math.floor((hover.point.position.x - win.pad + win.gap / 2) / (win.icon + win.gap)) : -1

        Glass {
            id: pill
            anchors.bottom: parent.bottom
            width: row.width + win.pad * 2
            height: win.icon + win.pad * 2
            radius: 22

            Row {
                id: row
                anchors.centerIn: parent
                spacing: win.gap

                Repeater {
                    model: win.items
                    delegate: Item {
                        id: d
                        required property var modelData
                        required property int index
                        width: win.icon
                        height: win.icon

                        readonly property real cx: win.pad + index * (win.icon + win.gap) + win.icon / 2
                        readonly property real prox: hover.hovered
                            ? Math.exp(-Math.pow((hover.point.position.x - cx) / 62, 2)) : 0
                        scale: 1 + 0.55 * prox
                        z: prox
                        transformOrigin: Item.Bottom
                        Behavior on scale { NumberAnimation { duration: 70 } }

                        // dim the icon when every window of the app is minimized
                        readonly property bool allMin: {
                            const w = d.modelData.windows
                            if (w.length === 0) return false
                            for (const t of w) if (!win.isMin(t)) return false
                            return true
                        }
                        opacity: allMin ? 0.45 : 1
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        // launch bounce, like macOS: hops until the app's window appears
                        property real lift: 0
                        transform: Translate { y: -d.lift }
                        readonly property bool hasWins: d.modelData.windows.length > 0
                        onHasWinsChanged: if (hasWins) stopBounce()
                        function startBounce() { if (!hasWins) { bounce.restart(); bounceStop.restart() } }
                        function stopBounce() { bounce.stop(); bounceStop.stop(); lift = 0 }
                        SequentialAnimation {
                            id: bounce
                            loops: Animation.Infinite
                            NumberAnimation { target: d; property: "lift"; to: 20; duration: 260; easing.type: Easing.OutQuad }
                            NumberAnimation { target: d; property: "lift"; to: 0; duration: 300; easing.type: Easing.InQuad }
                        }
                        Timer { id: bounceStop; interval: 6000; onTriggered: d.stopBounce() }

                        Image {
                            anchors.fill: parent
                            source: Quickshell.iconPath(d.modelData.icon, "application-x-executable")
                            sourceSize: Qt.size(128, 128)
                            smooth: true
                            mipmap: true
                        }
                        Rectangle {
                            visible: d.modelData.windows.length > 0
                            width: 4; height: 4; radius: 2
                            color: Theme.text
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height + 3
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: m => {
                                const w = d.modelData.windows
                                if (m.button === Qt.MiddleButton || w.length === 0) {
                                    if (d.modelData.entry) { d.modelData.entry.execute(); d.startBounce() }
                                } else {
                                    const vis = w.filter(t => !win.isMin(t))
                                    if (vis.length === 0) {
                                        win.restore(w[0])   // everything minimized: bring it back
                                    } else {
                                        // click again to cycle through this app's windows
                                        let i = -1
                                        for (let n = 0; n < vis.length; n++) if (vis[n].activated) i = n
                                        vis[(i + 1) % vis.length].activate()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // app name above the hovered icon
        Glass {
            id: tip
            readonly property var cur: hit.hoverIndex >= 0 && hit.hoverIndex < win.items.length
                ? win.items[hit.hoverIndex] : null
            visible: cur !== null
            radius: 8
            width: tipText.implicitWidth + 20
            height: 24
            y: 2
            x: win.pad + hit.hoverIndex * (win.icon + win.gap) + win.icon / 2 - width / 2
            Txt { id: tipText; anchors.centerIn: parent; text: tip.cur ? tip.cur.name : ""; font.pixelSize: 12 }
        }
    }
}
