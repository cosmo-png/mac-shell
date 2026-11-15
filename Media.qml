pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// One place for "what is playing" and the live audio levels (cava), shared by the island and the music widget.
Singleton {
    id: m

    readonly property int count: 12
    readonly property var player: pick()
    readonly property bool playing: player !== null && player.playbackState === MprisPlaybackState.Playing
    property var levels: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]   // each 0..1
    property bool live: false

    function pick() {
        const ps = Mpris.players.values
        for (const p of ps) if (p.playbackState === MprisPlaybackState.Playing) return p
        return ps.length > 0 ? ps[0] : null
    }

    onPlayingChanged: if (!playing) levels = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    // cava only runs while music is playing
    Process {
        id: cava
        command: ["cava", "-p", Quickshell.shellPath("cava.conf")]
        running: m.playing
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";").filter(s => s !== "").map(Number)
                if (v.length === 0) return
                m.live = true
                m.levels = v.slice(0, m.count).map(x => Math.min(100, x) / 100)
            }
        }
        onRunningChanged: if (!running) m.live = false
    }

    // fallback when cava is not installed
    Timer {
        interval: 180
        running: m.playing && !m.live
        repeat: true
        onTriggered: m.levels = Array.from({ length: m.count }, () => 0.15 + Math.random() * 0.7)
    }
}
