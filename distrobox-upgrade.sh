#!/bin/bash

# Distrobox Auto-Upgrade Setup Script
# Description: Configures automatic updates for Distrobox containers
# Author: Diogo Pessoa
# Version: 1.1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to find Distrobox executable
find_distrobox_executable() {
    local distrobox_path
    
    distrobox_path=$(which distrobox-upgrade 2>/dev/null || \
                     find / -name "distrobox-upgrade" 2>/dev/null | head -n 1)
    
    # If not found, try to find distrobox
    if [ -z "$distrobox_path" ]; then
        distrobox_path=$(which distrobox 2>/dev/null || \
                        find / -name "distrobox" 2>/dev/null | head -n 1)
        if [ -n "$distrobox_path" ]; then
            distrobox_path="$distrobox_path upgrade"
        fi
    fi
    
    echo "$distrobox_path"
}

# Function to create service file
create_service_file() {
    local distrobox_path="$1"
    local service_file="$HOME/.config/systemd/user/distrobox-upgrade.service"
    
    print_status "Creating service file: $service_file"
    
    mkdir -p "$(dirname "$service_file")"
    
    cat > "$service_file" << EOF
[Unit]
Description=Update all Distrobox containers 
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/distrobox-upgrade --all
# Optional: Notification after update (if in graphical environment)
ExecStartPost=/usr/bin/notify-send "📦️ Distrobox" "Containers updated successfully!"

[Install]
WantedBy=default.target
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Service file created successfully"
    else
        print_error "Failed to create service file"
        exit 1
    fi
}

# Function to create timer file
create_timer_file() {
    local choice="$1"
    local timer_file="$HOME/.config/systemd/user/distrobox-upgrade.timer"
    
    print_status "Creating timer file: $timer_file"
    
    case $choice in
        1)
            # Weekly update (Monday 01:00)
            cat > "$timer_file" << EOF
[Unit]
Description=Update Distrobox containers (weekly, Monday 10h)

[Timer]
# Runs every Monday
OnCalendar=Mon 10:00:00
# Tolerance for execution grouping
AccuracySec=1h
# Run if missed last window
Persistent=true

[Install]
WantedBy=timers.target
EOF
            print_success "Configured for WEEKLY update (Monday 10:00)"
            ;;
        2)
            # Daily update
            cat > "$timer_file" << EOF
[Unit]
Description=Update Distrobox containers (daily, 60s after boot)

[Timer]
# Runs 60 seconds after each system boot
OnBootSec=60s
# Tolerance for execution grouping
AccuracySec=1h
# Run if missed last window
Persistent=true

[Install]
WantedBy=timers.target
EOF
            print_success "Configured for DAILY update"
            ;;
        *)
            print_error "Invalid option"
            exit 1
            ;;
    esac
}

# Function to activate service
activate_service() {
    print_status "Reloading user services..."
    systemctl --user daemon-reload
    
    print_status "Activating timer..."
    if systemctl --user enable --now distrobox-upgrade.timer; then
        print_success "Timer activated successfully"
    else
        print_error "Failed to activate timer"
        exit 1
    fi
    
    # Pequena pausa para o systemd processar o timer
    sleep 2
    
    print_status "Checking schedule..."
    local timer_status
    timer_status=$(systemctl --user list-timers --all 2>/dev/null | grep distrobox-upgrade || true)
    
    if [ -n "$timer_status" ]; then
        print_success "Timer scheduled:"
        echo "$timer_status"
    else
        print_warning "Timer not listed. Checking status manually..."
        systemctl --user status distrobox-upgrade.timer --no-pager || \
        print_warning "It may take a few seconds for the timer to appear"
    fi
}

# Function to force timer recalculation
force_timer_recalculation() {
    print_status "Forcing timer recalculation..."
    systemctl --user stop distrobox-upgrade.timer 2>/dev/null || true
    systemctl --user start distrobox-upgrade.timer
    sleep 1
}

# Function to check and fix common issues
troubleshoot_timer() {
    print_status "Checking for possible issues..."
    
    # Check if timer file exists
    if [ ! -f "$HOME/.config/systemd/user/distrobox-upgrade.timer" ]; then
        print_error "Timer file not found"
        return 1
    fi
    
    # Verificar sintaxe do timer
    if systemd-analyze verify --user "$HOME/.config/systemd/user/distrobox-upgrade.timer" 2>&1; then
        print_success "Timer syntax is correct"
    else
        print_error "Problem with timer syntax"
        return 1
    fi
    
    # Force recalculation
    force_timer_recalculation
    
    return 0
}

# Função principal
main() {
    echo "================================================"
    echo " Automatic Update Configuration"
    echo " for Distrobox Containers"
    echo "================================================"
    echo ""
    
    # Check if systemd is available
    if ! command_exists systemctl; then
        print_error "Systemd not found. This script requires systemd."
        exit 1
    fi
    
    # Find Distrobox executable
    print_status "Looking for Distrobox executable..."
    DISTROBOX_PATH=$(find_distrobox_executable)
    
    if [ -z "$DISTROBOX_PATH" ]; then
        print_error "Distrobox not found. Please install it first."
        exit 1
    fi
    
    print_success "Distrobox found: $DISTROBOX_PATH"
    
    # Options menu
    echo ""
    echo "Select update type:"
    echo "1. Weekly Update (Monday 10:00)"
    echo "2. Daily Update (60s after boot)"
    echo ""
    read -p "Enter your choice (1 or 2): " choice
    
    # Create configuration files
    create_service_file "$DISTROBOX_PATH"
    create_timer_file "$choice"
    
    # Activate service
    echo ""
    activate_service
    
    # Verificação adicional para timers semanais
    if [ "$choice" -eq 1 ]; then
        echo ""
        troubleshoot_timer
        
        # Additional verification for weekly timers
        print_status "Check again after troubleshooting"
        local final_check
        final_check=$(systemctl --user list-timers --all 2>/dev/null | grep distrobox-upgrade || true)
        
        if [ -z "$final_check" ]; then
            print_warning "The timer may not show the next schedule."
            print_warning "This is normal for calendar timers that haven't run yet."
            print_warning "It will appear automatically when approaching the scheduled date."
        fi
    fi
    
    # Final information
    echo ""
    echo "================================================"
    print_success "Configuration completed successfully!"
    echo ""
    echo "Useful commands:"
    echo "  • Check status: systemctl --user status distrobox-upgrade.timer" 
    echo "  • Disable: systemctl --user disable distrobox-upgrade.timer"
    echo ""
    echo "For calendar timers, the next schedule may"
    echo "take a few minutes to appear in the list."
    echo "================================================"
}

# Check if interactive execution
if [ -t 0 ]; then
    main "$@"
else
    print_error "This script must be run interactively"
    exit 1
fi
