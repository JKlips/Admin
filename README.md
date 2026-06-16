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

echo "Waiting for session of $TARGET_USER..."

for i in {1..60}; do
    SESSION_ID=$(loginctl list-sessions --no-legend | awk -v user="$TARGET_USER" '$3 == user {print $1; exit}')

    if [ -n "$SESSION_ID" ]; then
        echo "Found session: $SESSION_ID"

        sleep 20

        echo "Locking session..."
        loginctl lock-session "$SESSION_ID"

        sleep 5

        echo "Typing password..."

        modprobe uinput || true

        SOCKET="/tmp/.ydotool_socket_auto_rdp"
        rm -f "$SOCKET"

        ydotoold --socket-path="$SOCKET" &
        YDOTOOL_PID=$!

        sleep 2

        export YDOTOOL_SOCKET="$SOCKET"

        # Разбудить экран / открыть поле пароля
        ydotool key 28:1 28:0
        sleep 1

        # Ввести пароль
        ydotool type "$PASSWORD"
        sleep 1

        # Нажать Enter
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
chmod +x /usr/local/bin/auto-login-rdp.sh
```
```
/etc/systemd/system/auto-login-rdp.service
```
```
[Unit]
Description=Run auto-login-rdp once after boot

[Timer]
OnBootSec=10s
AccuracySec=1s
Unit=auto-login-rdp.service
Persistent=false

[Install]
WantedBy=timers.target
```
```
systemctl daemon-reload

sudo systemctl enable auto-login-rdp.service
```
