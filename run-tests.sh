#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
test "$#" -le 1 || { echo 'Uso: ./run-tests.sh [directorio de VM nueva de 1 GiB]' >&2; exit 1; }
vm_dir=$(CDPATH= cd -- "${1:-$repo_dir/vm}" && pwd)
cd "$vm_dir"
for tool in qemu-img timeout sha256sum cmp; do command -v "$tool" >/dev/null; done
if [ -f qemu.pid ] && kill -0 "$(cat qemu.pid)" 2>/dev/null; then
    echo 'La VM debe estar apagada antes de iniciar esta prueba.' >&2; exit 1
fi
disk_bytes() {
    LC_ALL=C qemu-img info --output=human disk.qcow2 |
        sed -n 's/^virtual size:.*(\([0-9][0-9]*\) bytes).*$/\1/p'
}
[ "$(disk_bytes)" = 1073741824 ] || { echo 'Usa una copia de pruebas de 1 GiB; esta prueba la ampliará a 2 GiB.' >&2; exit 1; }
boot_timeout=${BOOT_TIMEOUT:-900}
case "$boot_timeout" in ''|*[!0-9]*|0) echo 'BOOT_TIMEOUT debe ser un entero positivo.' >&2; exit 1;; esac
log_dir=$(mktemp -d "$vm_dir/test-logs.XXXXXX")
log="$log_dir/results.log"
printf 'Registros: %s\nLa prueba ampliará esta copia a 2 GiB y la dejará encendida.\n' "$log_dir"
exec 3>&1
exec >"$log" 2>&1
finish() {
    result=$?
    trap - EXIT
    printf '%s\n' "$result" > "$log_dir/exit-code"
    tail -n 40 "$log" >&3
    printf '\nCódigo de salida: %s. Registro: %s\n' "$result" "$log" >&3
    exit "$result"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
phase() { printf '\n%s\n' "$*"; printf '%s\n' "$*" >&3; }
ready() {
    deadline=$(( $(date +%s) + boot_timeout ))
    until timeout 45 ./ssh.sh true 2>>"$log_dir/ssh-readiness.log"; do
        if [ "$(date +%s)" -ge "$deadline" ]; then
            echo 'SSH no estuvo disponible dentro del tiempo límite; revisa console.log.' >&2
            return 1
        fi
        sleep 5
    done
}
phase 'Arranque y comprobación de Debian ARM64 sin Docker'
./start.sh
ready
./ssh.sh sh -s < "$repo_dir/test-guest.sh"
boot_before=$(./ssh.sh cat /proc/sys/kernel/random/boot_id)
phase 'DNS y acceso a repositorios APT'
./ssh.sh 'getent ahostsv4 deb.debian.org && apt-get -o APT::Update::Error-Mode=any -o Acquire::Retries=2 update -qq'
phase 'Rechazo de ampliación con la VM encendida'
if ./resize-disk.sh 2G >"$log_dir/online-resize.log" 2>&1; then
    echo 'ERROR: se permitió ampliar la VM encendida'; exit 1
fi
grep -q 'Apaga primero' "$log_dir/online-resize.log"
phase 'Sincronización del kernel e initramfs'
sha256sum kernel initramfs > "$log_dir/kernel-before.txt"
./sync-kernel.sh
sha256sum kernel initramfs > "$log_dir/kernel-after.txt"
cmp "$log_dir/kernel-before.txt" "$log_dir/kernel-after.txt"
phase 'Apagado, integridad QCOW2 y ampliación de 1 a 2 GiB'
./stop.sh
qemu-img check disk.qcow2
./resize-disk.sh 2G
if ./resize-disk.sh 1G >"$log_dir/shrink.log" 2>&1; then
    echo 'ERROR: se permitió reducir el disco'; exit 1
fi
[ "$(disk_bytes)" = 2147483648 ]
phase 'Nuevo arranque y persistencia'
./start.sh
ready
boot_after=$(./ssh.sh cat /proc/sys/kernel/random/boot_id)
[ "$boot_before" != "$boot_after" ]
./ssh.sh sh -s < "$repo_dir/test-expanded.sh"
./ssh.sh 'set -e; for unit in ssh vm-prepare systemd-networkd; do systemctl is-active "$unit"; done; failed=$(systemctl --failed --no-legend --plain); test -z "$failed"; free -m'
phase 'ALL TESTS PASSED'
