#!/bin/bash
set -euxo pipefail

# Domyślny dysk systemowy
DISK="/dev/sda"

echo "[*] Reinstalling GRUB on ${DISK}..."

# Instalacja kernela z RPM
dnf install -y /root/kernel-core*.rpm

# Odświeżenie initramfs (dracut)
echo "[*] Regenerating initramfs..."
for KERNEL_VERSION in $(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n'); do
    dracut --force --kver "${KERNEL_VERSION}"
done

# Reinstall GRUB na dysku
echo "[*] Reinstalling GRUB..."
grub2-install "${DISK}"

# Regeneracja konfiguracji GRUB-a
echo "[*] Regenerating GRUB config..."
grub2-mkconfig -o /boot/grub2/grub.cfg

# Synchronizacja danych na dysk
sync

echo "[+] GRUB reinstalled and configured successfully."
