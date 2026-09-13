# Construcción del paquete

La construcción local se realiza como root en Alpine Linux x86_64, con Docker,
QEMU user-mode ARM64 registrado en binfmt_misc, qemu-img, e2fsprogs, Python 3 y xz.
Estos requisitos son del constructor; el usuario final solo necesita QEMU y SSH.

1. Extraer un contenedor **nuevo** de `debian:12-slim` para `linux/arm64` a un directorio `rootfs`.
2. Copiar la resolución DNS del anfitrión y montar temporalmente proc y dev en esa raíz.
3. Crear `usr/sbin/policy-rc.d` con `exit 101` para que los servicios no arranquen durante la instalación.
4. Instalar con APT, sin recomendados: `linux-image-cloud-arm64 initramfs-tools systemd-sysv openssh-server iproute2 e2fsprogs ca-certificates`.
5. Configurar `MODULES=list` y `COMPRESS=gzip` en `etc/initramfs-tools/conf.d/90-qemu`; poner `virtio_pci`, `virtio_blk`, `virtio_net`, `virtio_rng`, `ext4` y `vfat` en `etc/initramfs-tools/modules`. Regenerar el initramfs con esa configuración. Comprobar `dpkg --audit`; desmontar proc y dev antes de crear la imagen.
6. Ejecutar `python3 configure-rootfs.py /ruta/absoluta/rootfs` desde el anfitrión.
7. Borrar índices APT, archivos DEB descargados, logs e identidades temporales. Conservar las licencias/copyright de los paquetes.
8. Crear un archivo raw de 1 GiB y poblar ext4 con `mkfs.ext4 -F -m 0 -d rootfs disk.raw`.
9. Extraer de `rootfs/boot` el kernel e initramfs. QEMU recibe el kernel ARM64 descomprimido como `kernel` y el initramfs como `initramfs`.
10. Convertir con `qemu-img convert -f raw -O qcow2 -c disk.raw disk.qcow2`.
11. Probar una copia, manteniendo intacto el paquete limpio: arranque, SSH, arquitectura, ausencia de Docker, escritura y ampliación de 1 a 2 GiB tras apagar.
12. Empaquetar los scripts, documentación, `disk.qcow2`, `kernel` e `initramfs` en `debian-arm64-min.tar.xz`; generar SHA256SUMS.

No incluir `rootfs`, `.git`, claves SSH, sockets, logs ni discos usados en las pruebas.
`PACKAGES.txt` registra las versiones incluidas; las fuentes de los paquetes Debian
están disponibles en los repositorios Debian y Debian Security correspondientes.

No es una compilación reproducible byte a byte: APT toma las actualizaciones disponibles
de Debian 12 al construir. Las pruebas y tamaños de esta construcción se registran en `RESULTS.md`.
