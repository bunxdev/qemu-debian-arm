#!/bin/sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
umask 077
if [ -f qemu.pid ] && kill -0 "$(cat qemu.pid)" 2>/dev/null; then
    echo 'La VM ya está iniciada.'; exit 0
fi
[ ! -f qemu.pid ] || rm qemu.pid
command -v qemu-system-aarch64 >/dev/null
[ -f disk.qcow2 ] && [ -f kernel ] && [ -f initramfs ]
mkdir -p seed
if [ ! -f id_ed25519 ]; then
    ssh-keygen -q -t ed25519 -N '' -f id_ed25519
fi
ssh-keygen -y -f id_ed25519 > seed/authorized_keys
qemu-system-aarch64 \
    -name debian-arm64-min -machine virt -cpu max -accel tcg,thread=multi \
    -m "${VM_RAM_MB:-512}" -smp "${VM_CPUS:-1}" \
    -kernel kernel -initrd initramfs \
    -append 'console=ttyAMA0 root=/dev/vda rootfstype=ext4 rw quiet' \
    -drive if=none,id=rootdisk,file=disk.qcow2,format=qcow2,discard=unmap \
    -device virtio-blk-pci,drive=rootdisk \
    -fw_cfg name=opt/vm/ssh-key,file=seed/authorized_keys \
    -netdev "user,id=net,hostfwd=tcp:127.0.0.1:${VM_SSH_PORT:-2222}-:22,hostfwd=tcp:127.0.0.1:${VM_HTTP_PORT:-8080}-:8080" \
    -device virtio-net-pci,netdev=net,romfile= -device virtio-rng-pci \
    -display none -monitor none \
    -chardev socket,id=serial,path=serial.sock,server=on,wait=off,logfile=console.log \
    -serial chardev:serial -pidfile qemu.pid -daemonize
echo "VM iniciada. SSH: 127.0.0.1:${VM_SSH_PORT:-2222}. El primer arranque puede tardar."
