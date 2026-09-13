#!/bin/sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [ ! -f qemu.pid ] || ! kill -0 "$(cat qemu.pid)" 2>/dev/null; then
    echo 'La VM está apagada.'; exit 0
fi
vm_pid=$(cat qemu.pid)
./ssh.sh systemctl --no-block --no-wall start poweroff.target || { echo 'No se pudo solicitar el apagado por SSH.' >&2; exit 1; }
count=0
while kill -0 "$vm_pid" 2>/dev/null; do
    count=$((count + 1))
    if [ "$count" -gt 120 ]; then
        echo 'El apagado no ha terminado. Revisa console.log antes de tocar el disco.' >&2
        exit 1
    fi
    sleep 5
done
echo 'VM apagada; ya puedes copiar o ampliar el disco.'
