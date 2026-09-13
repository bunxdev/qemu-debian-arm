#!/bin/sh
set -eu
# Ejecutar en la copia de pruebas después de ampliar a 2G y arrancar de nuevo.
test "$(cat /root/persistence-proof)" = debian-min-persistence-ok
blocks=$(df -kP / | awk 'NR==2 {print $2}')
test "$blocks" -gt 1900000
df -h /
cat /proc/sys/kernel/random/boot_id
systemctl --no-pager status vm-prepare.service
echo '2G FILESYSTEM GROWTH AND PERSISTENCE: PASSED'
