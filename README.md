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

## Preparar y probar un servidor Debian/Ubuntu recién instalado

Como root (o usando sudo para instalar paquetes):

```sh
apt-get update
apt-get install -y --no-install-recommends git ca-certificates
git clone https://github.com/bunxdev/qemu-debian-arm.git
cd qemu-debian-arm
./debian-setup.sh
./run-tests.sh
```

`debian-setup.sh` instala las herramientas ausentes y descarga la Release v0.1.1 en `./vm`.
No inicia la VM ni sobrescribe un destino existente. `download-vm.sh` verifica el SHA256
fijado en el código antes de extraer; puede usarse directamente si QEMU y las herramientas ya están instalados.
Estos scripts están en el repositorio; no hay que volver a descargar una imagen diferente de Debian.

`run-tests.sh` arranca una copia **apagada de 1 GiB**, verifica Debian ARM64 sin Docker,
SSH, DNS, APT y sincronización del kernel; comprueba el rechazo de cambios de tamaño en ejecución,
apaga, verifica QCOW2, amplía a 2 GiB y comprueba el nuevo arranque y la persistencia.
Escribe `/root/persistence-proof` dentro del invitado y descarga índices APT.
Deja la copia de pruebas encendida con 2 GiB; no se ejecuta otra vez sobre esa misma copia ampliada.
Los registros y el código de salida quedan en `vm/test-logs.*/`.
Si falla, conserva la VM y los registros para diagnosticarla; no fuerza el apagado.

```sh
# Entrar después de las pruebas:
./vm/ssh.sh
# O preparar otra copia y usar otros puertos:
./download-vm.sh ./otra-vm
VM_SSH_PORT=2223 VM_HTTP_PORT=8081 ./run-tests.sh ./otra-vm
```

`BOOT_TIMEOUT=900` permite hasta 15 minutos por arranque; puede aumentarse para emulación lenta.
La instalación y la prueba completa se repitieron satisfactoriamente en un servidor Debian 13 recién formateado; véase `RESULTS.md`.

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
