# Resultados de la construcción

Debian 12 ARM64, kernel `6.1.0-53-cloud-arm64`. Pruebas realizadas en
Alpine Linux x86_64 mediante QEMU de sistema y TCG, con 512 MiB de RAM y 1 CPU virtual.
**No incluye Docker. Android/Termux todavía no se ha probado en un dispositivo real.**

- Arranque directo del kernel, sin firmware UEFI: correcto.
- SSH con clave generada para la copia: correcto.
- Arquitectura `aarch64`, Debian 12, virtualización identificada como `qemu`: correctos.
- Ausencia del comando Docker: comprobada.
- Disco inicial: 1 GiB virtual; Debian muestra 974 MiB de sistema de archivos,
  253 MiB usados y aproximadamente 705 MiB disponibles.
- Rechazo de ampliación con la VM encendida: comprobado.
- Ampliación del disco apagado de 1 a 2 GiB: correcta.
- Rechazo de reducción a 1 GiB: comprobado.
- Ampliación automática de ext4 a 524288 bloques de 4 KiB: correcta.
- Persistencia de un archivo después de apagar, ampliar y arrancar: correcta.
- Espacio después de ampliar: 2,0 GiB totales, 253 MiB usados, unos 1,7 GiB libres.
- Sincronización del kernel e initramfs desde el invitado: hashes idénticos.
- Apagado con el script definitivo y comprobación QCOW2: correctos, sin errores de imagen.
- Arranque con el ajuste final de tiempos de dispositivos: correcto; SSH, red y preparación activos, sin unidades fallidas.

Los scripts `test-guest.sh` y `test-expanded.sh` permiten repetir las comprobaciones
sobre una copia de pruebas. La imagen que se distribuye está limpia y conserva
1 GiB de capacidad: no contiene claves SSH generadas, archivos de prueba ni datos personales.
`PACKAGES.txt` registra los paquetes instalados.

Los tiempos de arranque de este anfitrión se midieron en minutos. El rendimiento
en un teléfono tendrá que medirse allí. Para tolerar la emulación lenta, systemd
usa tiempos de inicio y detección de dispositivos de 300 segundos.

## Validación adicional en Debian 13 x86_64

La descarga pública de v0.1.0 coincidió con su SHA256. QEMU 10.0.13 instalado
sin paquetes recomendados expuso una dependencia de la ROM PXE `efi-virtio.rom`.
Se corrigió con `romfile=` en la tarjeta virtio-net; el arranque directo no necesita PXE.
La corrección se incluye en v0.1.1.

Con 512 MiB de RAM y una CPU virtual pasaron: arranque, SSH, identificación QEMU,
Debian 12 ARM64 sin Docker, resolución DNS, actualización de índices APT desde Internet,
apagado, integridad QCOW2, ampliación de 1 a 2 GiB, rechazo de reducción y persistencia.
SSH, red y preparación quedaron activos, sin unidades fallidas.
El invitado informó 41 MiB de RAM usados y 436 MiB disponibles en la comprobación final.
Esta prueba adicional también usa Linux; Android/Termux sigue pendiente de probar.

## Repetición desde un servidor recién formateado — 2026-09-13

Anfitrión Debian 13 x86_64 sin QEMU ni proyecto preinstalados. Se clonó el
repositorio público y se ejecutaron `debian-setup.sh` y `run-tests.sh` sobre
la Release v0.1.1, cuyo SHA256 se verificó antes de extraerla.

La primera ejecución detectó un fallo en el lector de tamaño del script de pruebas:
la salida JSON de QEMU 10 incluye tamaños de imágenes hijas además del disco virtual.
El commit `6eaece0` corrige la lectura usando la línea de capacidad de la salida
humana con `LC_ALL=C`. Se descargó esta corrección desde GitHub y se repitió
la prueba sobre la copia intacta de 1 GiB.

Resultado: **ALL TESTS PASSED**, código de salida **0**.

- Debian 12, ARM64 (`aarch64`), QEMU y ausencia de Docker: correctos.
- SSH, DNS y actualización de índices APT: correctos.
- Sincronización de kernel e initramfs: hashes idénticos.
- Rechazo de ampliación en ejecución, apagado e integridad QCOW2: correctos.
- Ampliación de 1 a 2 GiB y rechazo de reducción: correctos.
- Nuevo arranque, crecimiento de ext4 y persistencia del archivo de prueba: correctos.
- SSH, red y preparación activos, sin unidades fallidas.
- Disco final: 2,0 GiB, 272 MiB usados y aproximadamente 1,7 GiB disponibles.
- RAM del invitado: 42 MiB usados y 436 MiB disponibles en la comprobación final.
- `dpkg --audit` del anfitrión no informó problemas.

La VM de pruebas quedó encendida en `/root/qemu-debian-arm/vm`.
El registro completo quedó en `vm/test-logs.c8VXzH/results.log`, con su estado
numérico en `exit-code`. Esta validación no sustituye la prueba pendiente en Android/Termux.
