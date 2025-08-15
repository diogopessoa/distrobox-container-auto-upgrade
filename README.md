# Distrobox Auto-Upgrade Systemd Service

Keep your Distrobox containers automatically updated on any Linux system that uses Systemd.

## Features
1. **Weekly automatic updates** for all Distrobox containers
2. Optional desktop notifications
3. Flexible scheduling (weekly or daily)

## Installation

### 1. Create the Systemd service file

First, locate your Distrobox executable path:
```bash
which distrobox-upgrade || find / -name "distrobox-upgrade" 2>/dev/null
```

Create the service file:
```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/distrobox-upgrade.service
```

Paste this content (adjust the path if needed):
```ini
[Unit]
Description=Update all Distrobox containers
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/distrobox-upgrade --all
# Optional: Desktop notification (requires GUI)
ExecStartPost=/usr/bin/notify-send "Distrobox" "Containers updated successfully!"
```

### 2. Configure the timer

#### Option A: Weekly updates
```bash
nano ~/.config/systemd/user/distrobox-upgrade.timer
```
```ini
[Unit]
Description=Update Distrobox containers (60s after login + weekly)

[Timer]
# Runs 60 seconds after first login
OnBootSec=60s
# Repeats weekly after last activation
OnUnitActiveSec=1w
# Execution window
AccuracySec=1h
# Run if missed last window
Persistent=true

[Install]
WantedBy=timers.target
```

#### Option B: Daily updates (after each boot)
```bash
nano ~/.config/systemd/user/distrobox-upgrade.timer
```
```ini
[Unit]
Description=Update Distrobox containers (60s after boot)

[Timer]
# Runs 60 seconds after each system boot
OnBootSec=60s
# Execution window
AccuracySec=1h
# Run if missed last window
Persistent=true

[Install]
WantedBy=timers.target
```

### 3. Enable the service
```bash
# Reload user services
systemctl --user daemon-reload

# Enable and start the timer
systemctl --user enable --now distrobox-upgrade.timer

# Verify the schedule
systemctl --user list-timers --all
```

Expected output:
```plaintext
NEXT                        LEFT          LAST                        PASSED       UNIT                         ACTIVATES
Mon 2025-08-22 10:00:00 -03 6 days       Mon 2025-08-11 10:00:00 -03 1h 12min ago distrobox-upgrade.timer      distrobox-upgrade.service
```

## Testing

### Manual execution
```bash
systemctl --user start distrobox-upgrade.service
```

## License
MIT

## Credits
- [Distrobox](https://github.com/89luca89/distrobox)
- [systemd](https://github.com/systemd/systemd)
