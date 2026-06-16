# Auto login ubuntu
```
nano ~/.config/systemd/user/rdp-kick-after-login.service
```
```
[Unit]
Description=Lock and unlock GNOME session once after boot
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/bin/bash -lc 'FLAG="$XDG_RUNTIME_DIR/rdp-lock-unlock-done"; [ -f "$FLAG" ] && exit 0; touch "$FLAG"; sleep 5; loginctl lock-sessions; sleep 5; loginctl unlock-sessions'

[Install]
WantedBy=default.target
```
```
systemctl --user daemon-reload
systemctl --user enable rdp-kick-after-login.service
```
