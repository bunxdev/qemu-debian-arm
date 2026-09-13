#!/bin/sh
set -eu
repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
test "$#" -le 1 || { echo 'Uso: ./debian-setup.sh [directorio NUEVO]' >&2; exit 1; }
destination=${1:-"$repo_dir/vm"}
if [ -e "$destination" ] || [ -L "$destination" ]; then
    echo 'El destino ya existe; no se modificará. Usa otro directorio.' >&2; exit 1
fi
[ "$(id -u)" -eq 0 ] || { echo 'Ejecuta este instalador como root o mediante sudo.' >&2; exit 1; }
. /etc/os-release
case "$ID" in debian|ubuntu) ;; *) echo 'Este instalador requiere Debian o Ubuntu.' >&2; exit 1;; esac
# Instalar solo herramientas ausentes; no solicitar actualizaciones de SSH ya instalado.
packages=''
command -v qemu-system-aarch64 >/dev/null 2>&1 || packages="$packages qemu-system-arm"
command -v qemu-img >/dev/null 2>&1 || packages="$packages qemu-utils"
if ! command -v ssh >/dev/null 2>&1 || ! command -v ssh-keygen >/dev/null 2>&1; then
    packages="$packages openssh-client"
fi
command -v curl >/dev/null 2>&1 || packages="$packages curl"
command -v xz >/dev/null 2>&1 || packages="$packages xz-utils"
command -v tar >/dev/null 2>&1 || packages="$packages tar"
test -s /etc/ssl/certs/ca-certificates.crt || packages="$packages ca-certificates"
if [ -n "$packages" ]; then
    apt-get update
    # División intencional: packages contiene únicamente nombres constantes definidos arriba.
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-upgrade $packages
fi
"$repo_dir/download-vm.sh" "$destination"
printf 'Para arrancar: %s/start.sh\nPara probar: %s/run-tests.sh %s\n' "$destination" "$repo_dir" "$destination"
