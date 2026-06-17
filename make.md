# Auto login ubuntu

```
ydotool
```
```
/usr/local/bin/auto-login-rdp.sh
```
```
#!/bin/bash

TARGET_USER="user"
PASSWORD="111111"

echo "Waiting for GNOME session of $TARGET_USER..."

for i in {1..60}; do
    SESSION_ID=$(loginctl list-sessions --no-legend | awk -v user="$TARGET_USER" '$3 == user {print $1; exit}')

    if [ -n "$SESSION_ID" ]; then
        echo "Found session: $SESSION_ID"

        sleep 3

        echo "Locking session..."
        loginctl lock-session "$SESSION_ID"

        sleep 3

        echo "Starting ydotool..."
        modprobe uinput || true

        SOCKET="/tmp/.ydotool_socket_auto_rdp"
        rm -f "$SOCKET"

        ydotoold --socket-path="$SOCKET" &
        YDOTOOL_PID=$!

        sleep 2

        export YDOTOOL_SOCKET="$SOCKET"

        echo "Wake lock screen..."
        ydotool key 28:1 28:0

        sleep 1

        echo "Typing password..."
        ydotool type "$PASSWORD"

        sleep 1

        echo "Press Enter..."
        ydotool key 28:1 28:0

        sleep 2

        kill "$YDOTOOL_PID" || true

        echo "Done"
        exit 0
    fi

    sleep 2
done

echo "Session not found"
exit 1
```

```
sudo chmod 755 /usr/local/bin/auto-login-rdp.sh
sudo chown root:root /usr/local/bin/auto-login-rdp.sh
```

```
/etc/systemd/system/auto-login-rdp.service
```

```
[Unit]
Description=Run auto-login-rdp once after boot

[Service]
Type=oneshot
ExecStart=/usr/local/bin/auto-login-rdp.sh
```


```
/etc/systemd/system/auto-login-rdp.timer
```


```
[Unit]
Description=Run auto-login-rdp timer once after boot

[Timer]
OnBootSec=5s
AccuracySec=1s
Unit=auto-login-rdp.service
Persistent=false

[Install]
WantedBy=timers.target
```
```
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash video=HDMI-A-1:1920x1080@60e drm_kms_helper.edid_firmware=HDMI-A-1:edid/1920x1080.bin"
```
```
sudo systemctl daemon-reload
sudo systemctl reset-failed auto-login-rdp.service auto-login-rdp.timer
sudo systemctl enable --now auto-login-rdp.timer
```
