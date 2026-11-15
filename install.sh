#!/usr/bin/env bash
# macshell installer.  ./install.sh            link this folder into ~/.config/quickshell/macshell
#                      ./install.sh --deps     also install dependencies (Arch / CachyOS)
#                      ./install.sh --copy     copy files instead of linking
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/macshell"
deps=(quickshell brightnessctl wl-clipboard inter-font networkmanager bluez-utils cava)
copy=0

for a in "$@"; do
  case "$a" in
    --deps)
      if command -v pacman >/dev/null; then sudo pacman -S --needed "${deps[@]}"
      else echo "Not an Arch system. Install by hand: ${deps[*]}"; fi ;;
    --copy) copy=1 ;;
    *) echo "unknown option: $a"; exit 1 ;;
  esac
done

mkdir -p "$(dirname "$dest")"
if [[ -e "$dest" || -L "$dest" ]]; then
  if [[ -L "$dest" ]]; then rm "$dest"
  else mv "$dest" "$dest.bak-$(date +%s)"; echo "Existing config saved as $dest.bak-*"; fi
fi

if [[ $copy -eq 1 ]]; then
  mkdir -p "$dest"
  cp -r "$here"/*.qml "$dest"/
  echo "Copied to $dest"
else
  ln -s "$here" "$dest"
  echo "Linked $dest -> $here  (git pull updates it)"
fi

echo
echo "Try it:   pkill -x quickshell; quickshell -c macshell"
echo "Keybinds: see README.md"
