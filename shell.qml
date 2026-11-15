//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// macshell: a small macOS-style desktop shell for Hyprland.
// Menu bar, dock, Spotlight, Control Center + notifications, volume/brightness pop-up.
ShellRoot {
    id: root

    property bool spotlightOpen: false
    property bool centerOpen: false
    property bool dnd: false
    property bool widgetsOpen: true
    property real centerClosedAt: 0

    function toggleCenter() {
        if (centerOpen) centerOpen = false
        else if (Date.now() - centerClosedAt > 250) centerOpen = true
    }

    NotificationServer {
        id: notifs
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: true
        onNotification: n => {
            n.tracked = true
            if (!root.dnd) {
                popups.add(n)
                island.alert(n)
            }
        }
    }

    // one menu bar per monitor
    Variants {
        model: Quickshell.screens
        MenuBar {
            required property var modelData
            screen: modelData
            shell: root
        }
    }

    Island { id: island; shell: root }
    Variants {
        model: Quickshell.screens
        Corners {
            required property var modelData
            screen: modelData
        }
    }

    Dock { shell: root }
    Spotlight { shell: root }
    ControlCenter { shell: root; notifs: notifs }
    Widgets { shell: root }
    Popups { id: popups }
    Osd { id: osd }

    // keybinds call these:  qs -c macshell ipc call macshell spotlight
    IpcHandler {
        target: "macshell"
        function spotlight(): void { root.spotlightOpen = !root.spotlightOpen }
        function center(): void { root.toggleCenter() }
        function dnd(): void { root.dnd = !root.dnd }
        function widgets(): void { root.widgetsOpen = !root.widgetsOpen }
        function theme(): void { Theme.preset = (Theme.preset + 1) % Theme.presets.length }
        function brightness(): void { osd.showBrightness() }
    }
}
