import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win

    property var shell
    property string query: ""
    property int sel: 0
    property var results: search(query)

    readonly property bool open: shell.spotlightOpen
    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "macshell-spotlight"
    WlrLayershell.keyboardFocus: shell.spotlightOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            input.text = ""
            sel = 0
            input.forceActiveFocus()
        }
    }
    onResultsChanged: sel = 0

    function activate(i) {
        const r = results[i]
        if (!r) return
        shell.spotlightOpen = false
        r.run()
    }

    // apps, calculator, system actions, web fallback
    function search(q) {
        q = q.trim()
        if (q === "") return []
        const lq = q.toLowerCase()
        const out = []

        // calculator: only digits and operators ever reach eval
        if (/^[0-9+\-*\/().,%^ ]+$/.test(q) && /[0-9]/.test(q) && /[+\-*\/^%]/.test(q.replace(/^\s*-/, ""))) {
            try {
                const v = eval(q.replace(/\^/g, "**").replace(/,/g, "."))
                if (typeof v === "number" && isFinite(v)) {
                    const r = String(Math.round(v * 1e10) / 1e10)
                    out.push({ title: r, subtitle: "Calculator - press Return to copy", icon: "", glyph: "=",
                               run: () => Quickshell.execDetached(["wl-copy", r]) })
                }
            } catch (e) {}
        }

        const scored = []
        for (const a of DesktopEntries.applications.values) {
            if (a.noDisplay) continue
            const n = a.name.toLowerCase()
            let s = 0
            if (n === lq) s = 100
            else if (n.startsWith(lq)) s = 80
            else if (n.includes(" " + lq)) s = 60
            else if (n.includes(lq)) s = 40
            else if ((a.genericName || "").toLowerCase().includes(lq)) s = 20
            else if (Array.prototype.some.call(a.keywords || [], k => k.toLowerCase().includes(lq))) s = 15
            if (s > 0) scored.push({ s: s, a: a })
        }
        scored.sort((x, y) => y.s - x.s || x.a.name.localeCompare(y.a.name))
        for (const e of scored.slice(0, 6))
            out.push({ title: e.a.name, subtitle: e.a.genericName || "Application", icon: e.a.icon, glyph: "A",
                       run: () => e.a.execute() })

        const acts = [
            ["Lock Screen", "L", () => Quickshell.execDetached(["loginctl", "lock-session"])],
            ["Sleep", "S", () => Quickshell.execDetached(["systemctl", "suspend"])],
            ["Restart", "R", () => Quickshell.execDetached(["systemctl", "reboot"])],
            ["Shut Down", "P", () => Quickshell.execDetached(["systemctl", "poweroff"])],
            ["Log Out", "O", () => Quickshell.execDetached(["hyprctl", "dispatch", "exit"])],
            ["Do Not Disturb", "D", () => { shell.dnd = !shell.dnd }],
            ["Control Center", "C", () => { shell.centerOpen = true }],
            ["Change Accent Color", "T", () => { Theme.preset = (Theme.preset + 1) % Theme.presets.length }]
        ]
        let n = 0
        for (const x of acts) {
            if (n < 2 && x[0].toLowerCase().includes(lq)) {
                out.push({ title: x[0], subtitle: "System", icon: "", glyph: x[1], run: x[2] })
                n++
            }
        }

        out.push({ title: "Search the web for \"" + q + "\"", subtitle: "Open in browser", icon: "", glyph: "G",
                   run: () => Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(q)]) })
        return out.slice(0, 8)
    }

    // soft dim behind the card
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.16)
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // click outside the card closes it
    MouseArea { anchors.fill: parent; onClicked: win.shell.spotlightOpen = false }

    Glass {
        id: card
        width: Math.min(640, parent.width - 32)
        height: 58 + (win.results.length > 0 ? win.results.length * 46 + 12 : 0)
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2
        radius: 20
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.94
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 0.7 } }

        MouseArea { anchors.fill: parent }   // clicks on the card must not close it

        Row {
            x: 18
            height: 58
            spacing: 12

            Item {
                width: 18; height: 18
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.sub
                }
                Rectangle {
                    x: 10; y: 12; width: 8; height: 2; radius: 1
                    color: Theme.sub
                    rotation: 45
                    transformOrigin: Item.Left
                }
            }

            TextInput {
                id: input
                width: card.width - 36 - 30
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 22
                selectionColor: Theme.accent
                clip: true
                onTextChanged: win.query = text

                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab) {
                        win.sel = Math.min(win.sel + 1, win.results.length - 1)
                        e.accepted = true
                    } else if (e.key === Qt.Key_Up) {
                        win.sel = Math.max(win.sel - 1, 0)
                        e.accepted = true
                    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        win.activate(win.sel)
                        e.accepted = true
                    } else if (e.key === Qt.Key_Escape) {
                        win.shell.spotlightOpen = false
                        e.accepted = true
                    }
                }

                Txt {
                    visible: input.text === ""
                    text: "Spotlight Search"
                    font.pixelSize: 22
                    color: Theme.sub
                }
            }
        }

        ListView {
            x: 6; y: 58
            width: card.width - 12
            height: win.results.length * 46
            interactive: false
            model: win.results

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 46
                radius: 12
                color: index === win.sel ? Theme.accent : "transparent"

                Row {
                    x: 12
                    height: parent.height
                    spacing: 12

                    Item {
                        width: 30; height: 30
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            anchors.fill: parent
                            visible: row.modelData.icon !== ""
                            source: row.modelData.icon !== "" ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                            sourceSize: Qt.size(64, 64)
                            smooth: true
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: row.modelData.icon === ""
                            radius: 8
                            color: Qt.rgba(1, 1, 1, 0.14)
                            Txt { anchors.centerIn: parent; text: row.modelData.glyph; font.pixelSize: 15 }
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Txt { text: row.modelData.title; font.pixelSize: 15; width: card.width - 100 }
                        Txt {
                            text: row.modelData.subtitle
                            font.pixelSize: 11
                            color: row.index === win.sel ? Qt.rgba(1, 1, 1, 0.75) : Theme.sub
                            width: card.width - 100
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: win.sel = row.index
                    onClicked: win.activate(row.index)
                }
            }
        }
    }
}
