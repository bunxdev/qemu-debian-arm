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
