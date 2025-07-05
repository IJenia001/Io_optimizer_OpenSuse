#!/bin/bash
# Оптимизация I/O и параметров ядра для openSUSE Tumbleweed (32GB RAM + 16GB VRAM)

set -e

echo "Применение оптимизаций производительности для openSUSE Tumbleweed..."

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    echo "Запустите скрипт от имени root (sudo $0)"
    exit 1
fi

# Параметры ядра
KERNEL_PARAMS="quiet splash=silent elevator=none spec_rstack_overflow=microcode intel_iommu=on iommu=pt amd_iommu=on security=selinux selinux=1"

# Обновление конфигурации GRUB
GRUB_CONFIG="/etc/default/grub"
if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_CONFIG"; then
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$KERNEL_PARAMS\"|" "$GRUB_CONFIG"
else
    echo "GRUB_CMDLINE_LINUX_DEFAULT=\"$KERNEL_PARAMS\"" >> "$GRUB_CONFIG"
fi

# Применение изменений GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg
echo "Параметры ядра обновлены. Требуется перезагрузка."

# Автоматическое определение и настройка планировщиков I/O
for blockdev in /sys/block/*; do
    devname=$(basename "$blockdev")
    scheduler_file="$blockdev/queue/scheduler"
    
    if [[ -f "$scheduler_file" ]]; then
        # Для NVMe
        if [[ $devname == nvme* ]]; then
            echo "none" > "$scheduler_file"
            echo "I/O scheduler для $devname установлен в 'none'"
        
        # Для SSD (включая eMMC)
        elif [[ $(cat "$blockdev/queue/rotational") == "0" ]]; then
            echo "mq-deadline" > "$scheduler_file"
            echo "I/O scheduler для $devname установлен в 'mq-deadline'"
        
        # Для HDD
        else
            echo "bfq" > "$scheduler_file"
            echo "I/O scheduler для $devname установлен в 'bfq'"
        fi
    fi
done

# Оптимизация параметров кэширования (учёт 32GB RAM)
SYSCTL_CONF="/etc/sysctl.d/99-io-optimizations.conf"
cat > "$SYSCTL_CONF" << EOF
# Оптимизации для системы с 32GB RAM
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 5000
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Настройки для 16GB VRAM (NVIDIA/AMD)
vm.min_free_kbytes = 65536
vm.watermark_scale_factor = 200
EOF

# Применение sysctl
sysctl --system
echo "Параметры кэширования оптимизированы"

# Настройки для графической памяти (если установлен NVIDIA)
NVIDIA_CONF="/etc/modprobe.d/nvidia-graphics.conf"
if modinfo nvidia &> /dev/null; then
    cat > "$NVIDIA_CONF" << EOF
options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x3; PowerMizerDefault=0x3"
options nvidia_drm modeset=1
EOF
    echo "Оптимизации NVIDIA применены (16GB VRAM)"
    update-initramfs -u
fi

echo "Оптимизация успешно завершена! Требуется перезагрузка."
