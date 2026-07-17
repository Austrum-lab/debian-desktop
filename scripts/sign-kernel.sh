#!/usr/bin/env bash
#
# Sign kernel with MOK key for Secure Boot
#
# Prerequisites:
#   sudo apt install sbsigntool mokutil
#
# First time setup:
#   openssl req -new -x509 -newkey rsa:4096 -keyout /opt/_src/MOK.priv.pem \
#     -out /opt/_src/MOK.crt.pem -nodes -days 3650 -subj "/CN=TKG Kernel MOK/"
#   openssl x509 -in /opt/_src/MOK.crt.pem -outform DER -out /opt/_src/MOK.crt.der
#   sudo mokutil --import /opt/_src/MOK.crt.der
#   # Reboot and enroll key in MOK manager
#
# Usage:
#   sudo ./sign-kernel.sh
#

set -e

MOK_FOLDER=/opt/_src
MOK_NAME=MOK
KERNEL_VERSION=$(uname -r)
#KERNEL_VERSION=7.1.3-tkg-bore

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Signing kernel ${KERNEL_VERSION}..."

# Backup current kernel
echo "Backing up current kernel..."
mv /boot/vmlinuz-${KERNEL_VERSION} /boot/bak-vmlinuz-${KERNEL_VERSION}.bak

# Sign the kernel
echo "Signing kernel..."
sbsign --key ${MOK_FOLDER}/${MOK_NAME}.priv.pem \
       --cert ${MOK_FOLDER}/${MOK_NAME}.crt.pem \
       --output /boot/vmlinuz-${KERNEL_VERSION} \
       /boot/bak-vmlinuz-${KERNEL_VERSION}.bak

# Sign DKMS modules (optional)
# for MOD in $(find /lib/modules/${KERNEL_VERSION}/updates/dkms/ -name "*.ko"); do
#   echo "Signing ${MOD}..."
#   ${SIGN_TOOL} sha256 ${MOK_FOLDER}/${MOK_NAME}.priv.pem ${MOK_FOLDER}/${MOK_NAME}.crt.pem ${MOD}
# done

# Update GRUB
echo "Updating GRUB..."
update-grub

echo "Kernel signed successfully!"
