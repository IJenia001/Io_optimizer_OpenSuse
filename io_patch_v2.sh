#!/bin/bash
# Патч для оптимизации производительности I/O и настройки параметров ядра в openSUSE

set -e

echo "Applying performance optimizations for openSUSE..."

### Check permissions
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

### Define kernel parameters
KERNEL_PARAMS="quiet splash elevator=none spec_rstack_overflow=microcode"

### Update GRUB configuration
GRUB_CONFIG="/etc/default/grub"
if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_CONFIG"; then
    sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$KERNEL_PARAMS\"|" "$GRUB_CONFIG"
else
    echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$KERNEL_PARAMS\"" | sudo tee -a "$GRUB_CONFIG"
fi

### Update GRUB
if [ -d "/boot/efi" ]; then
    sudo grub2-mkconfig -o /boot/efi/EFI/opensuse/grub.cfg
else
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
fi

echo "Kernel parameters updated. Reboot required to apply changes."

### Optimize I/O scheduler for NVMe
NVME_DEVICE="/sys/block/nvme0n1/queue/scheduler"
if [ -f "$NVME_DEVICE" ]; then
    echo "none" | sudo tee "$NVME_DEVICE"
    echo "I/O scheduler for NVMe set to 'none'."
fi

### Optimize I/O for HDD
HDD_DEVICE="/sys/block/sda/queue/scheduler"
if [ -f "$HDD_DEVICE" ]; then
    echo "deadline" | sudo tee "$HDD_DEVICE"
    echo "I/O scheduler for HDD set to 'deadline'."
fi

### Optimize caching parameters
sudo echo 100 > /proc/sys/vm/dirty_ratio
sudo echo 20 > /proc/sys/vm/dirty_background_ratio

### Create performance report


echo "Optimization applied successfully. Please reboot your system to apply kernel parameters."
