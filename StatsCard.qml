import Quickshell
import Quickshell.Io
import QtQuick

Card {
    id: c
    width: 300
    height: 150

    property real cpu: 0
    property real ram: 0
    property real disk: 0
    property var last: null

    // read /proc directly, only while the widget is on screen
    FileView { id: statFile; path: "/proc/stat" }
    FileView { id: memFile; path: "/proc/meminfo" }
    Process {
        id: df
        command: ["df", "-P", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n")[1]
                if (l) c.disk = parseInt(l.split(/\s+/)[4]) / 100
            }
        }
    }

    Timer {
        interval: 2500
        running: c.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload()
            const f = statFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = f[3] + f[4]
            const total = f.reduce((a, b) => a + b, 0)
            if (c.last) {
                const dt = total - c.last.total
                const di = idle - c.last.idle
                if (dt > 0) c.cpu = 1 - di / dt
            }
            c.last = { total: total, idle: idle }

            memFile.reload()
            const m = memFile.text()
            const tot = parseInt(m.match(/MemTotal:\s+(\d+)/)[1])
            const av = parseInt(m.match(/MemAvailable:\s+(\d+)/)[1])
            c.ram = 1 - av / tot
        }
    }
    Timer {
        interval: 300000
        running: c.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: df.running = true
    }

    Row {
        anchors.centerIn: parent
        spacing: 11
        Ring { value: c.cpu; text: Math.round(c.cpu * 100) + "%"; label: "CPU" }
        Ring { value: c.ram; text: Math.round(c.ram * 100) + "%"; label: "Memory" }
        Ring { value: c.disk; text: Math.round(c.disk * 100) + "%"; label: "Disk" }
    }
}
