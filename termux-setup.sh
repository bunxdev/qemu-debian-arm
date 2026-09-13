#!/bin/sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if ! command -v pkg >/dev/null 2>&1; then
    echo 'Ejecuta este instalador dentro de Termux.' >&2; exit 1
fi
if [ ! -f disk.qcow2 ] || [ ! -f kernel ] || [ ! -f initramfs ]; then
    echo 'Extrae primero el paquete completo de la VM en este directorio; consulta README.md.' >&2
    exit 1
fi
pkg install -y qemu-system-aarch64-headless qemu-utils openssh xz-utils
exec ./start.sh
