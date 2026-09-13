#!/bin/sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# Usar después de apt upgrade y ANTES de apagar/reiniciar tras actualizar el kernel.
./ssh.sh 'cat /vmlinuz' > kernel.download
./ssh.sh 'cat /initrd.img' > initramfs.download
if gzip -t kernel.download 2>/dev/null; then
    gzip -dc kernel.download > kernel.next
else
    cp kernel.download kernel.next
fi
test -s kernel.next && test -s initramfs.download
mv kernel.next kernel
mv initramfs.download initramfs
rm kernel.download
echo 'Kernel e initramfs sincronizados. Ya puedes apagar y arrancar la VM.'
