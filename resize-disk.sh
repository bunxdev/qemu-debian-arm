#!/bin/sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [ "$#" -ne 1 ] || ! printf '%s\n' "$1" | grep -Eq '^[1-9][0-9]*[MGT]$'; then
    echo 'Uso: ./resize-disk.sh 8G (capacidad TOTAL, solo ampliar)' >&2; exit 1
fi
if [ -f qemu.pid ] && kill -0 "$(cat qemu.pid)" 2>/dev/null; then
    echo 'Apaga primero la VM con ./stop.sh.' >&2; exit 1
fi
# qemu-img exige --shrink para reducir. No se ofrece esa opción.
qemu-img resize -f qcow2 disk.qcow2 "$1"
echo 'Disco ampliado. Ejecuta ./start.sh; ext4 crecerá automáticamente al arrancar.'
