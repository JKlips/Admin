# Auto login ubuntu
```
nano ~/.config/systemd/user/rdp-kick-after-login.service
```
```
[Unit]
Description=Lock and unlock session once after login
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/bin/bash -lc 'sleep 20; loginctl lock-sessions; sleep 5; loginctl unlock-sessions'

[Install]
WantedBy=default.target
```
```
systemctl --user daemon-reload
systemctl --user enable rdp-kick-after-login.service
```
