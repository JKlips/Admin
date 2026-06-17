#!/bin/bash
# install-headless-display.sh
# Forces a video output to exist without a physical monitor.
# Useful for Ubuntu/GNOME Remote Desktop when RDP does not work without monitor.
#
# Usage:
#   sudo bash install-headless-display.sh
#   sudo bash install-headless-display.sh HDMI-A-1 1920x1080@60
#   sudo bash install-headless-display.sh DP-1 1920x1080@60
#
# After running: sudo reboot

set -euo pipefail

GRUB_FILE="/etc/default/grub"
MODE="${2:-1920x1080@60}"

if [ "${EUID}" -ne 0 ]; then
    echo "Run as root:"
    echo "sudo bash $0 HDMI-A-1 1920x1080@60"
    exit 1
fi

find_connector() {
    # 1) Prefer currently connected external display
    for s in /sys/class/drm/card*-*/status; do
        [ -f "$s" ] || continue
        name="$(basename "$(dirname "$s")")"
        connector="${name#card*-}"
        status="$(cat "$s" 2>/dev/null || true)"

        case "$connector" in
            eDP-*|LVDS-*) continue ;;
        esac

        if [ "$status" = "connected" ]; then
            echo "$connector"
            return 0
        fi
    done

    # 2) If no monitor is connected, pick first external connector
    for s in /sys/class/drm/card*-*/status; do
        [ -f "$s" ] || continue
        name="$(basename "$(dirname "$s")")"
        connector="${name#card*-}"

        case "$connector" in
            HDMI-A-*|DP-*|DVI-*|VGA-*)
                echo "$connector"
                return 0
                ;;
        esac
    done

    return 1
}

CONNECTOR="${1:-}"

echo "Available connectors:"
for s in /sys/class/drm/card*-*/status; do
    [ -f "$s" ] || continue
    name="$(basename "$(dirname "$s")")"
    connector="${name#card*-}"
    status="$(cat "$s" 2>/dev/null || true)"
    echo "  ${connector}: ${status}"
done

if [ -z "$CONNECTOR" ]; then
    CONNECTOR="$(find_connector || true)"
fi

if [ -z "$CONNECTOR" ]; then
    echo "Could not detect connector."
    echo "Run manually, for example:"
    echo "sudo bash $0 HDMI-A-1 1920x1080@60"
    exit 1
fi

PARAM="video=${CONNECTOR}:${MODE}e"

echo
echo "Selected connector: ${CONNECTOR}"
echo "Selected mode:      ${MODE}"
echo "Kernel parameter:   ${PARAM}"
echo

if [ ! -f "$GRUB_FILE" ]; then
    echo "$GRUB_FILE not found. This script is for Ubuntu/Debian with GRUB."
    exit 1
fi

BACKUP="${GRUB_FILE}.backup.$(date +%F-%H%M%S)"
cp "$GRUB_FILE" "$BACKUP"
echo "Backup created: $BACKUP"

python3 - "$GRUB_FILE" "$PARAM" <<'PY'
import sys
import re

path = sys.argv[1]
param = sys.argv[2]

connector = param[len("video="):].split(":", 1)[0]
prefix = "video=" + connector + ":"

with open(path, "r", encoding="utf-8") as f:
    text = f.read()

pattern = re.compile(r'^(GRUB_CMDLINE_LINUX_DEFAULT=")([^"]*)(")', re.M)

def repl(match):
    before, value, after = match.groups()
    parts = value.split()
    parts = [p for p in parts if not p.startswith(prefix)]
    if param not in parts:
        parts.append(param)
    return before + " ".join(parts) + after

if pattern.search(text):
    text = pattern.sub(repl, text, count=1)
else:
    text += f'\nGRUB_CMDLINE_LINUX_DEFAULT="{param}"\n'

with open(path, "w", encoding="utf-8") as f:
    f.write(text)
PY

echo "Updating GRUB..."
if command -v update-grub >/dev/null 2>&1; then
    update-grub
else
    echo "update-grub not found. Run your distro GRUB update command manually."
    exit 1
fi

echo
echo "Done."
echo "Reboot now:"
echo "sudo reboot"
echo
echo "After reboot, check:"
echo "for x in /sys/class/drm/*/status; do echo \"\$x: \$(cat \"\$x\")\"; done"
