#!/bin/bash
set -euxo pipefail

echo "[OVH] Running CentOS 9 Stream boot setup..."

# Wymuś ponowne generowanie initramfs dla aktualnego jądra
CURRENT_KERNEL=$(uname -r)
echo "[OVH] Rebuilding initramfs for kernel: $CURRENT_KERNEL"
dracut -f --kver "$CURRENT_KERNEL"

# Wymuś instalację GRUB (dla BIOS i UEFI, OVH używa zazwyczaj BIOS/legacy boot, ale lepiej obsłużyć oba)
BOOT_DISK="/dev/sda"
MOUNTPOINT="/boot"

if [ -d "$MOUNTPOINT/EFI" ]; then
    echo "[OVH] Detected UEFI system. Installing GRUB EFI..."
    grub2-install --target=x86_64-efi --efi-directory="$MOUNTPOINT" --bootloader-id=centos --recheck --removable || true
else
    echo "[OVH] Installing GRUB for BIOS..."
    grub2-install --target=i386-pc "$BOOT_DISK" --recheck
fi

# Zaktualizuj konfigurację GRUB
echo "[OVH] Generating grub.cfg..."
grub2-mkconfig -o /boot/grub2/grub.cfg

echo "[OVH] Boot configuration complete."
rm -f /root/.ovh/make_image_bootable.sh
rm -rf /root/.ovh/
