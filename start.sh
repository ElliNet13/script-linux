#!/usr/bin/env bash
set -e

# Load .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "No .env file found"
    echo "Using defaults."
fi

# Defaults (if not set in .env)
KERNEL="${KERNEL:-./vmlinuz}"
MEMORY="${MEMORY:-1024M}"

INITRD="./initramfs.cpio.gz"
ROOTFS="./rootfs.qcow2"

if [ ! -f "$ROOTFS" ]; then
    echo "rootfs not found: $ROOTFS"
    echo "Generating rootfs..."
    ./generaterootfs.sh
    echo "Done."
fi

if [ ! -f "$KERNEL" ]; then
    echo "Kernel not found: $KERNEL"
    exit 1
fi

if [ ! -f "$INITRD" ]; then
    echo "Initrd not found: $INITRD"
    echo "Generating initramfs..."
    ./generateinitramfs.sh
    echo "Done."
fi

CMDLINE="root=/dev/root rootfstype=9p rootflags=trans=virtio,version=9p2000.L console=ttyS0 init=/sbin/init rw"

echo "Starting QEMU..."
echo "Kernel: $KERNEL"
echo "Initrd: $INITRD"
echo "Rootfs: $ROOTFS"
echo "Memory: $MEMORY"

qemu-system-x86_64 \
  -kernel "$KERNEL" \
  -initrd "$INITRD" \
  -m "$MEMORY" \
  -nographic \
  -drive file="$ROOTFS",format=qcow2,if=none,id=drv0 \
  -device ahci,id=ahci0 \
  -device ide-hd,drive=drv0 \
  -serial mon:stdio \
  -append "console=ttyS0,115200n8 earlycon rdinit=/sbin/init root=/dev/sda rw"