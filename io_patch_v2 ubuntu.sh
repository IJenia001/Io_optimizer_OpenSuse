#!/bin/bash
# Патч для оптимизации производительности I/O и настройки параметров ядра в Ubuntu

set -e

echo "Применение оптимизаций производительности для Ubuntu..."

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    echo "Запустите скрипт от имени root (например, с помощью sudo)"
    exit 1
fi

# Определяем параметры ядра
KERNEL_PARAMS="quiet splash elevator=none spec_rstack_overflow=microcode"

# Обновляем конфигурацию GRUB
GRUB_CONFIG="/etc/default/grub"
if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_CONFIG"; then
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$KERNEL_PARAMS\"|" "$GRUB_CONFIG"
else
    echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$KERNEL_PARAMS\"" >> "$GRUB_CONFIG"
fi

# Обновляем конфигурацию GRUB
update-grub

echo "Параметры ядра обновлены. Перезагрузка системы необходима для применения изменений."

# Оптимизация I/O scheduler для NVMe
NVME_DEVICE="/sys/block/nvme0n1/queue/scheduler"
if [ -f "$NVME_DEVICE" ]; then
    echo "none" > "$NVME_DEVICE"
    echo "I/O scheduler для NVMe установлен в 'none'."
fi

# Оптимизация I/O scheduler для HDD
HDD_DEVICE="/sys/block/sda/queue/scheduler"
if [ -f "$HDD_DEVICE" ]; then
    echo "deadline" > "$HDD_DEVICE"
    echo "I/O scheduler для HDD установлен в 'deadline'."
fi

# Оптимизация параметров кэширования
echo 100 > /proc/sys/vm/dirty_ratio
echo 20 > /proc/sys/vm/dirty_background_ratio

echo "Оптимизация успешно применена. Пожалуйста, перезагрузите систему для применения параметров ядра."
