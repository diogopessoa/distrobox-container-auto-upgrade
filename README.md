# Distrobox Container Auto-Upgrade
Keep your Distrobox containers automatically updated on any Linux system that uses Systemd.

![Descrição da imagem](https://raw.githubusercontent.com/diogopessoa/distrobox-container-auto-upgrade/main/run-distrobox-container-auto-upgrade-1.png)

## Features
 1. 🟢 **Automatic updates** for all Distrobox containers
 2. 🟢 **Flexible scheduling** weekly or daily
 3. 🟢 **No sudo needed** run as normal user

## Prerequisites
- **systemd** the host system must have systemd by default  
- **Podman** or **Docker** on the host system (Linux)  
- **Distrobox** with container installed ([see how to install](https://github.com/89luca89/distrobox))

### Notice
This script works regardless of whether Distrobox is installed in the user folder or the root folder. However, container managers like [DistroShelf](https://flathub.org/pt-BR/apps/com.ranfdev.DistroShelf) or [BoxBuddy](https://flathub.org/pt-BR/apps/io.github.dvlv.boxbuddyrs) only recognize Distrobox installed in the root folder.

# Automatic Installation

The script will automatically create files in `~/.config/systemd/user/` and configure automatic updates according to your choice!

## How to Use

### 1. Download the script:
   ```bash
   cd ~/Downloads
   wget https://raw.githubusercontent.com/diogopessoa/distrobox-container-auto-upgrade/main/distrobox-upgrade.sh
   ```

### 2. Make the script executable:
   ```bash
   chmod +x distrobox-upgrade.sh
   ```

### 3. Run the script:
   ```bash
   ./distrobox-upgrade.sh
   ```

### 4. **Follow the interactive menu**
```
Select the update type:
1. Weekly Update (Wednesday 10:00)
2. Daily Update (60s after boot)

Enter your choice (1 or 2): 
```

### ✅ Done!


## Manual Installation

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
ExecStart=/usr/sbin/distrobox-upgrade --all
# Optional: Desktop notification (requires GUI)
ExecStartPost=/usr/bin/notify-send "📦️ Distrobox" "Containers updated successfully!"
```

### 2. Configure the timer

#### Option A: Weekly updates
```bash
nano ~/.config/systemd/user/distrobox-upgrade.timer
```
```ini
[Unit]
Description=Update Distrobox containers (weekly, Wednesday 10h)

[Timer]
# Execute every Wednesday at 10h
OnCalendar=Mon 10:00:00
# Tolerance for execution
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
