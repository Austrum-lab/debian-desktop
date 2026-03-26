#!/bin/bash
#
# Stop GDM and unload NVIDIA modules
# Useful for driver reinstallation or kernel switching
#
# Usage:
#   sudo ./nvidia_gdm_unload.sh
#

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo)"
    exit 1
fi

echo "Stopping GDM and NVIDIA services..."

systemctl stop gdm.service
systemctl stop nvidia-persistenced.service
systemctl stop nvidia-powerd.service

echo "Unloading NVIDIA modules..."

modprobe -r nvidia_wmi_ec_backlight
modprobe -r nvidia_uvm
modprobe -r nvidia_drm
modprobe -r nvidia_modeset
modprobe -r nvidia

echo "Done. NVIDIA modules unloaded."
