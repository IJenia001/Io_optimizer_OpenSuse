#!/bin/bash
# Патч для оптимизации производительности I/O и настройки параметров ядра в openSUSE

set -e

echo "Applying performance optimizations for openSUSE..."

### 1. Настройка параметров ядра через GRUB
KERNEL_PARAMS="quiet splash spec_rstack_overflow=microcode mitigations=off"
GRUB_CONFIG="/etc/default/grub"

if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_CONFIG"; then
    sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$KERNEL_PARAMS\"|" "$GRUB_CONFIG"
else
    echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$KERNEL_PARAMS\"" | sudo tee -a "$GRUB_CONFIG"
fi

# Обновляем GRUB
if [ -d "/boot/efi" ]; then
    sudo grub2-mkconfig -o /boot/efi/EFI/opensuse/grub.cfg
else
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
fi

echo "Kernel parameters updated. Reboot required to apply changes."

### 2. Оптимизация процессов и планировщиков
# Настройка ionice для kjournald
KJOURNALD_PID=$(pgrep kjournald || true)
if [ -n "$KJOURNALD_PID" ]; then
    sudo ionice -c3 -p $KJOURNALD_PID
    echo "Ionice applied to kjournald (PID: $KJOURNALD_PID)."
fi

# Настройка I/O планировщика
NVME_DEVICE="/sys/block/nvme0n1/queue/scheduler"
if [ -f "$NVME_DEVICE" ]; then
    echo "none" | sudo tee "$NVME_DEVICE"
    echo "I/O scheduler for NVMe set to 'none'."
fi

### 3. Завершение
cat <<EOF
Optimization applied successfully. Please reboot your system to apply kernel parameters.
Make sure to monitor performance using fio, sysbench, or other tools.
EOF
