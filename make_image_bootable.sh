#!/bin/bash
set -euxo pipefail

# Domyślny dysk systemowy
DISK="/dev/sda"

echo "[*] Reinstalling GRUB on ${DISK}..."

dnf install /root/kernel-core*.rpm

# Reinstall GRUB
grub2-install "${DISK}"

# Regenerate GRUB configuration
grub2-mkconfig -o /boot/grub2/grub.cfg

# Synchronize disk
sync

echo "[+] GRUB reinstalled and configured successfully."
