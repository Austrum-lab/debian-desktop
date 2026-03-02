#!/bin/bash
#
# Install base tools for Debian desktop
#
# Usage:
#   sudo ./base_tools.sh
#

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Installing base tools..."

readarray -t list < base_tools.txt

tools=""
for i in "${list[@]}"; do
    tools="${tools} ${i}"
done

apt install -y ${tools}

echo "Base tools installed successfully!"
