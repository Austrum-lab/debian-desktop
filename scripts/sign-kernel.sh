#!/usr/bin/env bash

MOK_FOLDER=/opt/_src
MOK_NAME=MOK
KERNEL_VERSION=$(uname -r)
#KERNEL_VERSION=6.18.2-tkg-bore

SIGN_TOOL="/usr/src/linux-headers-${KERNEL_VERSION}/scripts/sign-file"

# sudo apt install sbsigntool
# openssl req -new -x509 -newkey rsa:4096 -keyout ${MOK_FOLDER}/${MOK_NAME}.priv.pem -out ${MOK_FOLDER}/${MOK_NAME}.crt.pem -nodes -days 3650 -subj "/CN=TKG Kernel ${MOK_FOLDER}/${MOK_NAME}/"
#openssl x509 -in ${MOK_FOLDER}/${MOK_NAME}.crt.pem -outform DER -out ${MOK_FOLDER}/${MOK_NAME}.crt.der
#sudo mokutil --import ${MOK_FOLDER}/${MOK_NAME}.crt.der
# reboot -> Enroll ${MOK_FOLDER}/${MOK_NAME} -> continue -> password -> enter -> continue

mv /boot/vmlinuz-${KERNEL_VERSION} /boot/bak-vmlinuz-${KERNEL_VERSION}.bak
sbsign --key ${MOK_FOLDER}/${MOK_NAME}.priv.pem --cert ${MOK_FOLDER}/${MOK_NAME}.crt.pem --output /boot/vmlinuz-${KERNEL_VERSION} /boot/bak-vmlinuz-${KERNEL_VERSION}.bak


#for MOD in $(find /lib/modules/${KERNEL_VERSION}/updates/dkms/ -name "*.ko"); do
#  ${SIGN_TOOL} sha256 ${MOK_FOLDER}/${MOK_NAME}.priv.pem ${MOK_FOLDER}/${MOK_NAME}.crt.pem ${MOD}
#done

sudo update-grub
