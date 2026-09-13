# qemu-debian-arm

Una máquina virtual completa con kernel propio, Debian 12 y SSH. **No incluye Docker.**
Esquema: **Termux → QEMU → Debian ARM64**. No requiere Alpine ni PRoot.
Arranca directamente el kernel: no necesita firmware UEFI, ISO, cloud-init ni otra imagen base.
El disco ext4 ocupa todo el dispositivo virtual, sin particiones; se amplía automáticamente al arrancar.

## Descargar

[Paquete Debian ARM64 — ≈97 MiB](https://github.com/bunxdev/qemu-debian-arm/releases/download/v0.1.1/debian-arm64-min.tar.xz) · [SHA256SUMS](https://github.com/bunxdev/qemu-debian-arm/releases/download/v0.1.1/SHA256SUMS) · [Resultados de las pruebas](RESULTS.md)

## Instalar en Termux

```sh
pkg install qemu-system-aarch64-headless qemu-utils openssh xz-utils
# Extraer el paquete en el almacenamiento privado de Termux, dentro de $HOME.
tar -xJf debian-arm64-min.tar.xz
cd debian-arm64-min
./start.sh
./ssh.sh
```

El paquete contiene `disk.qcow2`, `kernel`, `initramfs` y estos scripts.
Una vez extraído, `./termux-setup.sh` también permite instalar las herramientas de Termux e iniciar la VM.
Clonar solo el repositorio no descarga esos tres archivos: son parte del paquete de distribución.
Termux/Android aún necesita una prueba en el dispositivo real. Las pruebas locales usan Linux x86_64 y TCG.
En Debian/Ubuntu anfitrión: `apt-get install --no-install-recommends qemu-system-arm qemu-utils openssh-client xz-utils`.
La tarjeta de red virtual tiene desactivada su ROM PXE, que no se necesita para el arranque directo.
En Alpine Linux anfitrión: `apk add qemu-system-aarch64 qemu-img openssh-client`.
No hace falta Docker en el anfitrión ni acceso a KVM.

El primer arranque genera una clave de cliente en el anfitrión y una clave de servidor dentro del invitado.
La clave pública se entrega mediante `fw_cfg` de QEMU y se valida antes de iniciar SSH; no hace falta un segundo disco.
Acceso root exclusivamente por clave SSH, sin contraseña predeterminada.
La emulación puede ser lenta; esperar al arranque antes de usar `ssh.sh`.
Los puertos se publican solo en localhost: SSH 2222, y 8080 del anfitrión hacia 8080 del invitado.

## Ampliar el disco

La capacidad inicial es **1 GiB**. El archivo QCOW2 crece según se escriben datos; 1 GiB de capacidad no significa 1 GiB de descarga.
Para cambiar la capacidad TOTAL a 8 GiB:

```sh
./stop.sh
./resize-disk.sh 8G
./start.sh
./ssh.sh df -h /
```

También sirven `16G`, `32G`, etc. El script solo permite crecer, nunca reducir.
Internamente ejecuta `qemu-img resize`; el invitado ejecuta `resize2fs /dev/vda` antes de iniciar SSH.
No hay que editar particiones. El espacio físico necesario depende de los datos que se escriban.
Para una copia de seguridad, apagar la VM y copiar el directorio completo antes de modificarlo.

## RAM, CPU y puertos

Por defecto: 512 MiB de RAM y 1 CPU virtual. Cambiar con la VM apagada:

```sh
VM_RAM_MB=1024 VM_CPUS=2 ./start.sh
```

Para usar otros puertos, mantener `VM_SSH_PORT` en los comandos posteriores:

```sh
export VM_SSH_PORT=2223 VM_HTTP_PORT=8081
./start.sh
./ssh.sh
./stop.sh
```

## Paquetes y kernel

Dentro de Debian se usa `apt`, como en cualquier instalación Debian. No se incluyen caches APT ni imágenes de contenedores.
Antes de instalar paquetes grandes conviene ampliar el disco.

Si una actualización cambia el kernel, hay que copiar el nuevo kernel y su initramfs al anfitrión **antes del siguiente arranque**:

```sh
./ssh.sh 'apt-get update && apt-get upgrade -y'
./sync-kernel.sh
./stop.sh
./start.sh
```

`sync-kernel.sh` mantiene los archivos externos alineados con los módulos del disco.

## Compartir y GitHub

Distribuir el paquete limpio generado durante la construcción. No distribuir una copia que contenga claves, historial o datos personales.
`.gitignore` excluye claves, imágenes de disco y archivos de ejecución.
El código va en Git; el paquete de la VM se publica como archivo de una Release.

Repositorio: https://github.com/bunxdev/qemu-debian-arm

El código y las instrucciones de construcción están en este repositorio.
La VM lista para usar está en [Releases](https://github.com/bunxdev/qemu-debian-arm/releases).
El paquete conserva su nombre `debian-arm64-min.tar.xz` y se extrae en `debian-arm64-min`.

Para verificar la descarga, guardar `SHA256SUMS` junto al paquete y ejecutar:

```sh
sha256sum -c SHA256SUMS
```

Fuentes: https://www.debian.org/ ; https://www.qemu.org/docs/master/tools/qemu-img.html
