#!/bin/bash
set -euo pipefail

export LC_ALL=C
export LANG=C
export LANGUAGE=C

# Ustawiamy non-interaktywny tryb dla yum/dnf (brak pytań)
export DNF_YUM_AUTOMATIC_YES=True

# --- mdadm.conf od nowa (RAID) ---
rm -f /etc/mdadm.conf
mdadm --detail --scan > /etc/mdadm.conf

# --- Konsola - przekopiowanie parametrów konsoli do GRUB ---
console_parameters="$(grep -Po '\bconsole=\S+' /proc/cmdline | paste -s -d" ")"

if ! grep -qF "$console_parameters" /etc/default/grub; then
    sed -Ei "s/(^GRUB_CMDLINE_LINUX=\"[^\"]*)\"/\1 $console_parameters\"/" /etc/default/grub
fi

# --- Instalacja ZFS jeśli potrzebne ---
if lsblk -lno FSTYPE | grep -qi zfs_member; then
    # Instalacja ZFS na RHEL wymaga repozytorium EPEL + ZFS-on-Linux repo
    dnf install -y epel-release
    dnf install -y https://zfsonlinux.org/epel/zfs-release.el9.noarch.rpm
    dnf module disable -y zfs
    dnf install -y kernel-devel zfs

    # Start i włączenie importu puli ZFS przy starcie
    systemctl enable zfs-import-scan.service
fi

# --- Konfiguracja GRUB ---

if [ -d /sys/firmware/efi ]; then
    echo "INFO - GRUB będzie skonfigurowany dla UEFI"
    dnf install -y grub2-efi-x64 shim
    grub2-install --target=x86_64-efi --efi-directory=/boot/efi --no-nvram --removable
    grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
else
    echo "INFO - GRUB będzie skonfigurowany dla BIOS (legacy boot)"
    dnf install -y grub2
    for dev in $(lsblk -dno NAME | sed 's|^|/dev/|'); do
        grub2-install "$dev"
    done
    grub2-mkconfig -o /boot/grub2/grub.cfg
fi

# --- Sprzątanie ---
dnf autoremove -y
dnf clean all

# --- Nowy unikalny identyfikator maszyny ---
rm -f /etc/machine-id
systemd-machine-id-setup

# --- Aktualizacja initramfs ---
# W RedHacie initramfs budujemy dracutem
dracut -f --regenerate-all

# --- Usuwanie śmieci (np. plików instalatora) ---
rm -rf /root/.ovh/

echo "INFO - Konfiguracja systemu zakończona pomyślnie."
