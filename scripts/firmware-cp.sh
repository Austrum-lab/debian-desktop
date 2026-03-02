#!/bin/bash
#
# Update firmware from linux-firmware repository
#
# Prerequisites:
#   git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git /opt/_src/linux-firmware
#
# Usage:
#   sudo ./firmware-cp.sh
#

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (sudo)"
    exit 1
fi

REPO_PATH=/opt/_src/linux-firmware

# Check if firmware repo exists
if [ ! -d "${REPO_PATH}" ]; then
    echo "Error: Firmware repository not found at ${REPO_PATH}"
    echo "Clone first:"
    echo "  git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git ${REPO_PATH}"
    exit 1
fi

FIRMWARE_LIST="amd,amdtee,amd-ucode,amdgpu,nvidia,cirrus,ath10k,ath11k,ath12k,intel/iwlwifi"

echo "Updating firmware..."

IFS=','
for i in ${FIRMWARE_LIST}; do
    echo "  Updating firmware for ${i}..."
    rsync -arhH --info=progress2 ${REPO_PATH}/${i}/. /lib/firmware/${i}/
done
unset IFS

# echo "Updating iwlwifi firmware..."
# rsync -arhH --info=progress2 ${REPO_PATH}/iwlwifi-*.{ucode,pnvm} /lib/firmware/

echo "Updating initramfs..."
update-initramfs -u -k all

echo "Firmware updated successfully!"
