# macshell

A small macOS-style desktop shell for **Hyprland**, written in Quickshell (QML).
Lean on purpose: no settings app, no widgets, no polling in the background.

| Part | What it does |
|------|--------------|
| Menu bar | Transparent bar: logo menu, red / yellow / green window buttons (close, minimize, maximize; Alt+green = fullscreen) (lock, sleep, restart, shut down, log out), active app name, workspace dots, tray, battery, control center button, clock |
| Dock | Pinned + running apps, hover magnification, running dots, click to focus / cycle windows, middle click for a new window |
| Spotlight | Apps, calculator, system actions, web search fallback |
| Control Center | Wi-Fi, Bluetooth, Do Not Disturb, brightness, volume, now playing, notification history |
| Notifications | Banners top right (own daemon, history in the Control Center) |
| Widgets | Desktop widgets on the bottom layer: clock with seconds line, CPU / memory / disk rings, calendar, now playing with an equalizer that follows the real audio (needs `cava`). Staggered entrance and hover animations; timers pause when hidden |
| Dynamic island | Black pill in the middle of the bar: live music bars while playing, hover to open a mini player, pops open for new notifications |
| Look | Rounded screen corners, 5 accent themes (cycle live), open / close animations, bouncing dock icons, light sweep on cards |
| Pop-up | Volume pop-up (automatic) and brightness pop-up (via keybind) |

## Install

Needs Hyprland, [Quickshell](https://quickshell.org) and a recent Arch-based system (tested target: CachyOS).

```bash
git clone https://github.com/YOUR-USERNAME/macshell.git
cd macshell
bash install.sh --deps     # --deps installs dependencies with pacman, skip it if you have them
```

The installer links the folder into `~/.config/quickshell/macshell`, so `git pull` updates it
(`bash install.sh --copy` copies the files instead).

## Run

Try it first, don't autostart yet:

```bash
pkill -x quickshell          # stop the current shell
quickshell -c macshell       # errors are printed in this terminal
```

Only one notification daemon can run at a time. Stop swaync / dunst / mako while testing.
Quickshell reloads by itself when you edit a file.

## Keybinds

Add these in your Hyprland config (use whatever syntax your version uses):

| Action | Command |
|--------|---------|
| Spotlight | `qs -c macshell ipc call macshell spotlight` |
| Control Center | `qs -c macshell ipc call macshell center` |
| Do Not Disturb | `qs -c macshell ipc call macshell dnd` |
| Next accent theme | `qs -c macshell ipc call macshell theme` |
| Show / hide widgets | `qs -c macshell ipc call macshell widgets` |
| Brightness pop-up | run after changing brightness: `brightnessctl set 5%+ && qs -c macshell ipc call macshell brightness` |

Autostart: run `qs -c macshell` at login.

## Blur (the "glass")

The shell draws translucent surfaces. Real blur is done by Hyprland through layer rules.
The layer namespaces are:

`macshell-bar`, `macshell-dock`, `macshell-spotlight`, `macshell-center`, `macshell-notify`, `macshell-osd`

Add a blur rule matching `macshell-.*` (the rule syntax depends on your Hyprland version).
Without blur it still works: raise `glass` alpha in `Theme.qml` for readability.

## Customize

Everything is in `Theme.qml`: accent `preset`, screen corners, island alerts, colors, radius, bar transparency, clock format,
pinned dock apps (desktop file ids), power menu commands.

## Files

```
install.sh      installer
shell.qml       entry point, notification server, IPC
Theme.qml       settings and colors
MenuBar.qml  Dock.qml  Spotlight.qml  ControlCenter.qml  Popups.qml  Osd.qml
Widgets.qml  ClockCard.qml  StatsCard.qml  CalendarCard.qml  MusicCard.qml   desktop widgets
Card.qml  Ring.qml  Glass.qml  Tile.qml  MacSlider.qml  Txt.qml   small shared pieces
```

## Not included (on purpose)

Clipboard history and file search in Spotlight, Liquid Glass refraction shaders, lock screen,
wallpaper manager, weather. Each can be added later as one more file.
