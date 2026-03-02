#!/bin/bash
#
# Install GNOME packages for Debian desktop
#
# Usage:
#   sudo ./gnome_install.sh
#

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Installing GNOME packages..."

readarray -t list < gnome_packages.txt

packages=""
for i in "${list[@]}"; do
    packages="${packages} ${i}"
done

apt install -y ${packages}

echo "GNOME packages installed successfully!"
